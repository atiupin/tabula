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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"Тред в /%@/", self.boardId];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.isLoaded = NO;
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshButton.frame = CGRectMake(0, 0, 320, 44);
    [self.refreshButton setTitle:@"Обновить тред" forState:UIControlStateNormal];
    [self.refreshButton setTitle:@"Загрузка..." forState:UIControlStateDisabled];
    [self.refreshButton addTarget:self action:@selector(loadMorePosts) forControlEvents:UIControlEventTouchUpInside];
    self.refreshButton.hidden = YES;
    
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:self.refreshButton.frame];
    [self.tableView.tableFooterView addSubview:self.refreshButton];
    UIView *endline = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0.5)];
    endline.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
    [self.tableView.tableFooterView addSubview:endline];
    
    //http://2ch.hk/makaba/mobile.fcgi?task=get_thread&board=mobi&thread=300665&post=1
    
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
            }
            
            NSUInteger indexArray[] = {0, postNum};
            self.thread.startingRow = [NSIndexPath indexPathWithIndexes:indexArray length:2];
        }
        
        [self cacheHeightForAllPosts];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (self.thread.posts.count != 0) {
                [self performSelectorOnMainThread:@selector(creationEnded) withObject:nil waitUntilDone:YES];
                if ([self.thread.startingRow indexAtPosition:1] == [self.thread.posts count]-1) {
                    if (self.tableView.contentSize.height > self.tableView.frame.size.height)
                    {
                        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
                        [self.self.tableView setContentOffset:offset animated:NO];
                    }
                } else if ([self.thread.startingRow indexAtPosition:1] != 0) {
                    [self.tableView scrollToRowAtIndexPath:self.thread.startingRow atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
            [self.thread updateDates];
            [self.thread updatePostIndexes];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self performSelectorOnMainThread:@selector(updateEnded) withObject:nil waitUntilDone:YES];
        });
    });
    
}

#pragma mark - Data updating

- (void)creationEnded {
    [super creationEnded];
    [self.tableView reloadData];
    [self updateLastPost];
    self.refreshButton.enabled = YES;
    self.refreshButton.hidden = NO;
    if (![[Constants makabaBoards] containsObject:self.boardId]) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)updateStarted {
    [super updateStarted];
    self.refreshButton.enabled = NO;
}

- (void)updateEnded {
    [super updateEnded];
    [self.tableView reloadData];
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
    return self.thread.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    Post *post = self.thread.posts[indexPath.row];
    
    [cell setPost:post];
    
    cell.comment.delegate = self;
    
    //похоже, что это единственный вариант надежно убить сепаратор между таблицей и футером
    if (indexPath.row == [self.thread.posts count]-1) {
        cell.separator.hidden = YES;
    } else {
        cell.separator.hidden = NO;
    }
    
    if (post.mediaBox.count == 1) {
        UITapGestureRecognizer *tgrImage = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapped:)];
        tgrImage.delegate = self;
        [cell.postImage addGestureRecognizer:tgrImage];
    } else if (post.mediaBox.count > 1 && post.mediaBox.count <= 4) {
        for (TapImageView *image in cell.mediaBox) {
            UITapGestureRecognizer *tgrImage = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapped:)];
            tgrImage.delegate = self;
            [image addGestureRecognizer:tgrImage];
        }
    }
    
    UITapGestureRecognizer *tgrCell = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearTextViewSelections)];
    tgrCell.delegate = self;
    [cell addGestureRecognizer:tgrCell];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Post *post = self.thread.posts[indexPath.row];
    return [self heightForPost:post];
}

#pragma mark - Text View Delegate
- (void)textViewDidChangeSelection:(UITextView *)textView {
    //это несколько стремный способ, но вариант вида superview-superview-superview ломается в восьмерке
    CGPoint point = [textView convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    PostCell *cell = (PostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    self.responder = cell.comment;
    if (textView.selectedRange.length != 0) {
        [cell.replyButton setTitle:@"Цитировать" forState:UIControlStateNormal];
    } else {
        [cell.replyButton setTitle:@"Ответить" forState:UIControlStateNormal];
    }
}

#pragma mark - Buttons

- (IBAction)replyButton:(id)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    PostCell *cell = (PostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [self replyOrQuoteWithCell:cell];
}

- (IBAction)showRepliesButton:(id)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    PostCell *cell = (PostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [self showRepliesWithCell:cell];
}

@end
