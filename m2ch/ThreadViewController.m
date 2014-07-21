//
//  ThreadViewController.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "GetRequestViewController.h"
#import "ThreadViewController.h"
#import "PostViewController.h"

@interface ThreadViewController ()

@end

@implementation ThreadViewController

static NSInteger postsOnPage = 35;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[PostTableViewCell class] forCellReuseIdentifier:@"reuseIndenifier"];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.navigationItem.title = [NSString stringWithFormat:@"Тред в /%@/", self.boardId];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.isLoaded = NO;
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshButton.frame = CGRectMake(0, 0, 320, 44);
    [self.refreshButton setTitle:@"Обновить тред" forState:UIControlStateNormal];
    [self.refreshButton setTitle:@"Загрузка..." forState:UIControlStateDisabled];
    [self.refreshButton addTarget:self action:@selector(loadMorePosts) forControlEvents:UIControlEventTouchUpInside];
    self.refreshButton.hidden = YES;
    
    self.tableView.tableFooterView = self.refreshButton;
    
    NSString *stringUrl = [NSString stringWithFormat:@"%@/makaba/mobile.fcgi?task=get_thread&board=%@&thread=%@&post=1", ROOT_URL, self.boardId, self.threadId];
    self.mainUrl = [NSURL URLWithString:stringUrl];
    [self loadDataForUrl:self.mainUrl isMainUrl:YES handleError:YES];
}

#pragma mark - Data loading and creating

- (void)loadMorePosts {
    NSString *lastNum = self.thread.linksReference[self.thread.linksReference.count-1];
    NSString *stringUrl = [NSString stringWithFormat:@"%@/makaba/mobile.fcgi?task=get_thread&board=%@&thread=%@&num=%@", ROOT_URL, self.boardId, self.threadId, lastNum];
    NSURL *url = [NSURL URLWithString:stringUrl];
    [self loadDataForUrl:url isMainUrl:NO handleError:YES];
}

- (void)createDataWithLocation:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    //асинхронное задание по созданию массива
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        self.thread = [Thread threadWithData:data andBoardId:self.boardId andThreadId:self.threadId];
        NSString *comboId = [NSString stringWithFormat:@"%@%@", self.boardId, self.threadId];
        
        //аналогично боард контроллеру ищем самую последнюю позицию
        NSArray *positionArray = [ThreadData MR_findByAttribute:@"name" withValue:comboId];
        if (positionArray.count != 0) {
            int oldCount = 0;
            for (ThreadData *thread in positionArray) {
                if (oldCount <= [thread.count intValue]) {
                    oldCount = [thread.count intValue];
                    self.thread.startingPost = thread.position;
                }
            }
        }
        
        //если перешли по ссылке
        if (self.postId) {
            NSUInteger postNum = [self.thread.linksReference indexOfObject:self.postId];
            NSUInteger indexArray[] = {0, postNum};
            self.thread.startingRow = [NSIndexPath indexPathWithIndexes:indexArray length:2];
        } else if (self.thread.startingPost) {
            NSUInteger postNum = [self.thread.linksReference indexOfObject:self.thread.startingPost];
            if (postNum == NSNotFound) {
                postNum = 0;
            } else {
                postNum += 1;
            }
            
            NSUInteger indexArray[] = {0, postNum};
            self.thread.startingRow = [NSIndexPath indexPathWithIndexes:indexArray length:2];
        }
        
        self.currentThread = [Thread currentThreadWithThread:self.thread andPosition:self.thread.startingRow];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (self.currentThread.posts.count != 0) {
                [self performSelectorOnMainThread:@selector(creationEnded) withObject:nil waitUntilDone:YES];
                if ([self.currentThread.startingRow indexAtPosition:1] != 0) {
                    [self.tableView scrollToRowAtIndexPath:self.currentThread.startingRow atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }
            } else {
                NSError *error = [NSError errorWithDomain:@"notnil" code:-666 userInfo:nil];
                [self performSelectorOnMainThread:@selector(errorMessage:) withObject:error waitUntilDone:YES];
            }
        });
    });
}

- (void)createChildDataWithLocation:(NSURL *)location {
    [super createChildDataWithLocation:location];
    NSData *data = [NSData dataWithContentsOfURL:location];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        Thread *childThread = [Thread threadWithData:data andBoardId:self.boardId andThreadId:self.threadId];
        
        if (childThread.posts.count != 0) {
            [childThread.posts removeObjectAtIndex:0];
            [childThread.linksReference removeObjectAtIndex:0];
            
            [self.thread.posts addObjectsFromArray:childThread.posts];
            [self.thread.linksReference addObjectsFromArray:childThread.linksReference];
            [self.thread updateReplies];
            
            self.currentThread.postsBottomLeft += childThread.posts.count;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self performSelectorOnMainThread:@selector(updateEnded) withObject:nil waitUntilDone:YES];
        });
    });

}

#pragma mark - Data updating

- (void)creationEnded {
    [super creationEnded];
    //обновление таблицы бросает исключения автолейаута, если нажать на назад пока оно выполняется, но программу это не крашит
    [self.tableView reloadData];
    [self updateLastPost];
    self.refreshButton.enabled = YES;
    self.refreshButton.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)updateStarted {
    [super updateStarted];
    self.refreshButton.enabled = NO;
}

- (void)updateEnded {
    [super updateEnded];
    [self loadMorePostsBottom];
    [self updateLastPost];
    self.refreshButton.enabled = YES;
}

- (void)updateLastPost {
    //запись последнего поста в БД
    NSString *position = self.thread.linksReference[self.thread.linksReference.count-1];
    NSString *comboId = [NSString stringWithFormat:@"%@%@", self.boardId, self.threadId];
    NSNumber *count = [NSNumber numberWithInteger:self.thread.posts.count];
    
    //надо бы вписать этот объект как проперти, но сейчас нет времени на тестинг
    NSArray *positionArray = [ThreadData MR_findByAttribute:@"name" withValue:comboId];
    for (ThreadData *threadData in positionArray) {
        [threadData MR_deleteEntity];
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        ThreadData *localThreadData = [ThreadData MR_createInContext:localContext];
        localThreadData.name = comboId;
        localThreadData.position = position;
        localThreadData.count = count;
    }];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentThread.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIndenifier"];
    
    [cell updateFonts];
    
    Post *post = self.currentThread.posts[indexPath.row];
    
    [cell setPost:post];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    cell.comment.delegate = self;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapped:)];
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(postLongPress:)];
    
    lpgr.minimumPressDuration = 0.5;
    [cell.comment setTag:cell.num];
    
    tgr.delegate = self;
    lpgr.delegate = self;
    
    [cell addGestureRecognizer:lpgr];
    [cell.postImage addGestureRecognizer:tgr];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Post *post = self.currentThread.posts[indexPath.row];
    return [self heightForPost:post];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UrlNinja *urlNinja = [[UrlNinja alloc]init];
    urlNinja.postId = self.currentThread.linksReference[indexPath.row];
    [self openPostWithUrlNinja:urlNinja];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(actionSheet.tag == 1) // лонгпресс по посту
    {
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        } else if (buttonIndex == 0) { // ответить
            if (![self.thread.postDraft isEqualToString:@""] && self.thread.postDraft) {
                self.thread.postDraft = [NSString stringWithFormat:@"%@%@\n", self.thread.postDraft, self.reply];
            } else {
                self.thread.postDraft = [NSString stringWithFormat:@"%@\n", self.reply];
            }
        } else if (buttonIndex == 1) { //ответ с цитатой
            if (![self.thread.postDraft isEqualToString:@""] && self.thread.postDraft) {
                self.thread.postDraft = [NSString stringWithFormat:@"%@\n%@\n%@\n", self.thread.postDraft, self.reply, self.quote];
            } else {
                self.thread.postDraft = [NSString stringWithFormat:@"%@\n%@\n", self.reply, self.quote];
            }
        }
        
        [self performSegueWithIdentifier:@"newPost" sender:self];
    } else {
        [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    }
}

- (void)postLongPress:(UIGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan){
        PostTableViewCell *cell = (PostTableViewCell *)sender.view;
        TTTAttributedLabel *post = cell.comment;
//        TTTAttributedLabel *post = (TTTAttributedLabel *)sender.view;
        self.reply = [@">>" stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)cell.num]];
        self.quote = [self makeQuote:post.text];
    
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:
          NSLocalizedString(@"Отмена", nil) destructiveButtonTitle:nil otherButtonTitles:
          NSLocalizedString(@"Ответить", nil),
          NSLocalizedString(@"Ответить с цитатой", nil), nil];
        actionSheet.tag = 1;
        [actionSheet showInView:self.view];
    }
}

- (NSString *)makeQuote:(NSString *)sourceString {
    NSMutableString *mString = [sourceString mutableCopy];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSRegularExpression *quoteReg = [NSRegularExpression regularExpressionWithPattern:@"^.+$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [quoteReg enumerateMatchesInString:sourceString options:0 range:NSMakeRange(0, sourceString.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [resultArray addObject:result];
    }];
    NSInteger shift = 0;
    for (NSTextCheckingResult *result in resultArray) {
        [mString insertString:@">" atIndex:result.range.location + shift];
        shift ++;
    }
    return mString;
}

#pragma mark - Loading and refreshing

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ((self.tableView.contentSize.height - self.tableView.contentOffset.y) < 3000 && self.isLoaded == YES && self.currentThread.postsBottomLeft !=0 && self.isUpdating == NO) {
        [self loadMorePostsBottom];
    }
    if (self.tableView.contentOffset.y < 3000 && self.isLoaded == YES && self.currentThread.postsTopLeft !=0 && self.isUpdating == NO) {
        [self loadMorePostsTop];
    }
}

- (void)loadMorePostsTop {
    self.isUpdating = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        NSInteger i = 0;
        CGPoint newContentOffset = CGPointMake(0, 0);
        
        if (self.currentThread.postsTopLeft > postsOnPage) {
            i = postsOnPage;
        }
        else {
            i = self.currentThread.postsTopLeft;
        }
        
        for (int k = 0; k < i; k++) {
            newContentOffset.y += [self heightForPost:[self.thread.posts objectAtIndex:self.currentThread.postsTopLeft+k-i]];
        }
        
        [self.currentThread insertMoreTopPostsFrom:self.thread];
        newContentOffset.y += self.tableView.contentOffset.y;
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
            [self.tableView setContentOffset:newContentOffset];
            self.isUpdating = NO;
        });
    });
}

- (void)loadMorePostsBottom {
    self.isUpdating = YES;
    self.refreshButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self.currentThread insertMoreBottomPostsFrom:self.thread];
        [self cacheHeightsForUpdatedIndexes];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView reloadData];
            [self updateLastPost];
            self.refreshButton.enabled = YES;
            self.isUpdating = NO;
        });
    });
}

- (CGFloat)cacheHeightsForUpdatedIndexes {
    CGFloat height = 0;
    for (NSIndexPath *indexPath in self.currentThread.updatedIndexes)
        height += [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:indexPath];
    return height;
}

@end
