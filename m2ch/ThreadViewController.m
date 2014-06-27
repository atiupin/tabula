//
//  ThreadViewController.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "ThreadViewController.h"
#import "BoardViewController.h"
#import "GetRequestViewController.h"
#import "UrlNinja.h"
#import "JTSImageViewController.h"
#import "JTSImageInfo.h"
#import "ThreadData.h"

@interface ThreadViewController ()

@end

@implementation ThreadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[PostTableViewCell class] forCellReuseIdentifier:@"reuseIndenifier"];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.navigationItem.title = [NSString stringWithFormat:@"Тред в /%@/", self.boardId];
    self.isLoaded = NO;
    
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIContentSizeCategoryDidChangeNotification
     object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         [self.tableView reloadData];
     }];
    
    //вынести куда-нибудь отсюда потом
    UIColor *moreButtonColor = [[UIColor alloc]initWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.moreButton.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 30);
    self.moreButton.backgroundColor = moreButtonColor;
    self.moreButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.moreButton.tintColor = [UIColor grayColor];
    
    [self.moreButton addTarget:self action:@selector(loadMorePostsTop) forControlEvents:UIControlEventTouchUpInside];
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshButton.frame = CGRectMake(0, 0, 320, 44);
    [self.refreshButton setTitle:@"Обновить тред" forState:UIControlStateNormal];
    [self.refreshButton setTitle:@"Загрузка..." forState:UIControlStateDisabled];
    
    [self.refreshButton addTarget:self action:@selector(loadUpdatedData) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableHeaderView = self.moreButton;
    self.tableView.tableFooterView = self.refreshButton;
    self.tableView.tableHeaderView.hidden = YES;
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    [self loadData];
}

#pragma mark - Data loading and creating

- (void)loadData {
    [self updateStarted];
    NSString *threadStringUrl = [NSString stringWithFormat:@"http://2ch.hk/makaba/mobile.fcgi?task=get_thread&board=%@&thread=%@&post=1", self.boardId, self.threadId];
    NSURL *threadUrl = [NSURL URLWithString:threadStringUrl];
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:threadUrl completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        [self masterThreadWithLocation:location];
    }];
    [task resume];
}

- (void)loadUpdatedData {
    [self updateStarted];
    NSString *lastNum = self.thread.linksReference[self.thread.linksReference.count-1];
    NSString *threadStringUrl = [NSString stringWithFormat:@"http://2ch.hk/makaba/mobile.fcgi?task=get_thread&board=%@&thread=%@&num=%@", self.boardId, self.threadId, lastNum];
    
    threadStringUrl = @"http://2ch.hk/makaba/mobile.fcgi?task=get_thread&board=de&thread=32239&num=99999";
    
    NSURL *threadUrl = [NSURL URLWithString:threadStringUrl];
    
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:threadUrl completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        [self childThreadWithLocation:location];
    }];
    [task resume];
}

- (void)masterThreadWithLocation:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    //асинхронное задание по созданию массива
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        self.thread = [self createThreadWithData:data];
        NSString *comboId = [NSString stringWithFormat:@"%@%@", self.boardId, self.threadId];
        
        NSArray *positionArray = [ThreadData MR_findByAttribute:@"name" withValue:comboId];
        if (positionArray.count != 0) {
            ThreadData *position = positionArray[positionArray.count - 1];
            self.thread.startingPost = position.position;
        }
        
        //начинаем тред с последненнего прочитанного поста
        if (self.thread.startingPost) {
            NSUInteger postNum = [self.thread.linksReference indexOfObject:self.thread.startingPost];
            if (postNum == NSNotFound) {
                postNum = 0;
            }
            NSUInteger indexArray[] = {0, postNum};
            self.thread.startingRow = [NSIndexPath indexPathWithIndexes:indexArray length:2];
        }
        
        self.currentThread = [Thread currentThreadWithThread:self.thread andPosition:self.thread.startingRow];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self performSelectorOnMainThread:@selector(creationEnded) withObject:nil waitUntilDone:YES];
            if ([self.currentThread.startingRow indexAtPosition:1] != 0) {
                [self scrollToRowAnimated:self.currentThread.startingRow isAnimated:NO];
            }
        });
    });
}

- (void)childThreadWithLocation:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        Thread *childThread = [self createThreadWithData:data];
        
        if (childThread.posts.count != 0) {
            [childThread.posts removeObjectAtIndex:0];
            [childThread.linksReference removeObjectAtIndex:0];
            
            [self.thread.posts addObjectsFromArray:childThread.posts];
            [self.thread.linksReference addObjectsFromArray:childThread.linksReference];
            
            self.currentThread.postsBottomLeft += childThread.posts.count;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self performSelectorOnMainThread:@selector(updateEnded) withObject:nil waitUntilDone:YES];
        });
    });

}

- (Thread *)createThreadWithData:(NSData *)data {
    
    NSError *dataError = nil;
    NSArray *dataArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];
    
    Thread *thread = [[Thread alloc]init];
    thread.posts = [NSMutableArray array];
    thread.linksReference = [NSMutableArray array];
    
    for (NSDictionary *dic in dataArray) {
        Post *post = [Post postWithDictionary:dic andBoardId:self.boardId];
        [thread.posts addObject:post];
        [thread.linksReference addObject:[NSString stringWithFormat:@"%ld", (long)post.num]];
    }
    return thread;
}

#pragma mark - Data updating

- (void)updateStarted {
    self.refreshButton.enabled = NO;
    self.isLoaded = NO;
}

- (void)creationEnded {
    //обновление таблицы бросает исключения автолейаута, если нажать на назад пока оно выполняется, но программу это не крашит
    [self.tableView reloadData];
    self.refreshButton.enabled = YES;
    self.tableView.tableHeaderView.hidden = NO;
    self.isLoaded = YES;
    [self updateHeader];
    [self updateLastPost];
}

- (void)updateEnded {
    [self loadMorePostsBottom];
    self.refreshButton.enabled = YES;
    self.isLoaded = YES;
    [self updateLastPost];
}

- (void)updateLastPost {
    //запись последнего поста в БД
    NSString *position = self.thread.linksReference[self.thread.linksReference.count-1];
    NSString *comboId = [NSString stringWithFormat:@"%@%@", self.boardId, self.threadId];
    NSNumber *count = [NSNumber numberWithInteger:self.thread.posts.count];
    
    //ммммаксимум быдлокодерская реализация сохрания поста в базу, которая плодить объекты и засирает диск. Так и не понял как апдейтнуть конкретный объект или создать его, если его нет
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        ThreadData *localThreadData = [ThreadData MR_createInContext:localContext];
        localThreadData.name = comboId;
        localThreadData.position = position;
        localThreadData.count = count;
    }];
}

- (void)updateHeader {
    if (self.currentThread.postsTopLeft == 0) {
        self.tableView.tableHeaderView = nil;
    } else {
        NSUInteger postCount = self.currentThread.postsTopLeft;
        Declension *postDeclension = [Declension stringWithPostCount:postCount];
        NSString *postString = [NSString stringWithFormat:@"Еще %@", postDeclension.output];
        [self.moreButton setTitle:postString forState:UIControlStateNormal];
    }
}


#pragma mark - Session stuff
//чтобы компилятор не ругался

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
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
    
    if (self == self.navigationController.topViewController) {
        
        Post *post = self.currentThread.posts[indexPath.row];
        
        if (post.postHeight) {
            return post.postHeight;
        } else {
        
            PostTableViewCell *cell = [[PostTableViewCell alloc]init];
            
            [cell setPost:post];
            
            [cell setNeedsUpdateConstraints];
            [cell updateConstraintsIfNeeded];
            
            cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
            
            [cell setNeedsLayout];
            [cell layoutIfNeeded];
            
            CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            
            height += 1;
            post.postHeight = height;
            [self.currentThread.posts removeObjectAtIndex:indexPath.row];
            [self.currentThread.posts insertObject:post atIndex:indexPath.row];
           
            return height;
        }
    }
    
    return 0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut animations:^
     {
         [[self.tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
     } completion: NULL];
}

#pragma mark - Posting and draft handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"newPost"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        GetRequestViewController *destinationController = (GetRequestViewController *)navigationController.topViewController;
        [destinationController setBoardId:self.boardId];
        [destinationController setThreadId:self.threadId];
        [destinationController setDraft:self.thread.postDraft];
        destinationController.postView.text = self.thread.postDraft;
        destinationController.delegate = self;
    }
}

- (void)postCanceled:(NSString *)draft{
    self.thread.postDraft = draft;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postPosted {
    [self loadUpdatedData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(__unused TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {

    UrlNinja *urlNinja = [UrlNinja unWithUrl:url];
    
    switch (urlNinja.type) {
        case boardLink: {
            //открыть борду
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            BoardViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"BoardTag"];
            controller.boardId = urlNinja.boardId;
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case boardThreadLink: {
            //открыть тред
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            ThreadViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTag"];
            controller.boardId = urlNinja.boardId;
            controller.threadId = urlNinja.threadId;
            
            //без этого фачится размер заголовка
            controller.navigationItem.title = [NSString stringWithFormat:@"Тред в /%@/", urlNinja.boardId];

            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case boardThreadPostLink:
            //проскроллить страницу
            if ([urlNinja.boardId isEqualToString:self.boardId] && [urlNinja.threadId isEqualToString:self.threadId]) {
                NSIndexPath *index = [NSIndexPath indexPathForRow:[self.thread.linksReference indexOfObject:urlNinja.postId] inSection:0];
                [self scrollToRowAnimated:index isAnimated:YES];
                }
                //открыть тред и проскроллить страницу
                else {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                    ThreadViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTag"];
                    controller.boardId = urlNinja.boardId;
                    controller.threadId = urlNinja.threadId;
                    controller.postId = urlNinja.postId;
                    [self.navigationController pushViewController:controller animated:YES];
                    break;
                }
            break;
        default: {
            //внешня ссылка - предложение открыть в сафари
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:NSLocalizedString(@"Отмена", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Открыть ссылку в Safari", nil), nil];
            actionSheet.tag = 2;
            [actionSheet showInView:self.view];
            break;
        }
    }
}

- (void)scrollToRowAnimated: (NSIndexPath *)index isAnimated:(BOOL)animated {
    
    //вычисления для анимации
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:index];
    CGRect superRect = [self.tableView convertRect:cellRect toView:[self.tableView superview]];
    
    [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionTop animated:animated];
    
    //анимация, если пост уже на топе пользователя, 64 это магическое число обозначающее высоту скроллбара, потом надо переделать на нормальное
    if (superRect.origin.y == 64.0) {
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut animations:^
         {
             [[self.tableView cellForRowAtIndexPath:index] setHighlighted:YES animated:YES];
         } completion:^(BOOL finished)
         {
             [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut animations:^
              {
                  [[self.tableView cellForRowAtIndexPath:index] setHighlighted:NO animated:YES];
              } completion: NULL];
         }];
    }
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
        
    } else if (actionSheet.tag == 2) { //клик по ссылке
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        }
        //кстати, на конфе видел, что это хуевое решение, потому что юиаппликейнеш не должен за это отвечать и это как-то решается через делегирование
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
    }
}

- (void)imageTapped:(UITapGestureRecognizer *)sender {

    TapImageView *image = (TapImageView *)sender.view;
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    
    NSLog(@"%@", image.bigImageUrl);
    imageInfo.imageURL = image.bigImageUrl;
    imageInfo.referenceRect = image.frame;
    imageInfo.referenceView = image.superview;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundStyle_ScaledDimmed];
    
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOffscreen];
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

//десять часов возни в попытках нормально обновлять таблицу во время скролла а-ля Вконтакте не дали результа. Без глюков все обновляется только тогда, когда стоит на месте, во всяком случае вверх
//не очень понятно почему это происходит, то ли из-за работы скролл контроллера, то ли из того, что вычисление высот ячеек занимает время даже с кешированием
//в дальнейшем нужно попробовать вычислять их в бекграунде

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.tableView.contentOffset.y < 3000 && self.isLoaded == YES && self.currentThread.postsTopLeft !=0) {
        [self loadMorePostsTop];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ((self.tableView.contentSize.height - self.tableView.contentOffset.y) < 3000 && self.isLoaded == YES && self.currentThread.postsBottomLeft !=0) {
        [self loadMorePostsBottom];
    }
}

- (void)loadMorePostsTop {

    [self.currentThread insertMoreTopPostsFrom:self.thread];
    
    CGPoint newContentOffset = self.tableView.contentOffset;
    [self.tableView reloadData];
    [self updateHeader];

    for (NSIndexPath *indexPath in self.currentThread.updatedIndexes)
        newContentOffset.y += [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:indexPath];
    
    if (self.currentThread.postsTopLeft == 0) {
        newContentOffset.y -= 30;
    }
    
    [self.tableView setContentOffset:newContentOffset];
}

- (void)loadMorePostsBottom {
    [self.currentThread insertMoreBottomPostsFrom:self.thread];
    [self.tableView reloadData];
}

@end
