//
//  BoardViewController.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "BoardViewController.h"
#import "ThreadViewController.h"
#import "UrlNinja.h"
#import "JTSImageViewController.h"
#import "JTSImageInfo.h"

@interface BoardViewController ()

@end

@implementation BoardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
//    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.refreshControl beginRefreshing];
//        [self.refreshControl endRefreshing];
//    });
    
    [self.tableView registerClass:[ThreadTableViewCell class] forCellReuseIdentifier:@"reuseIndenifier"];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    [self loadData];
    
}

- (void)loadData {
    
    NSString *boardStringUrl = [[@"http://2ch.hk/" stringByAppendingString:self.boardId]stringByAppendingString:@"/wakaba.json"];
    NSURL *boardUrl = [NSURL URLWithString:boardStringUrl];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:boardUrl];
    [task resume];
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {

    NSData *data = [NSData dataWithContentsOfURL:location];

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        NSError *dataError = nil;
        NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];
        self.threadsList = [NSMutableArray array];
        
        NSArray *threadsArray = [dataDictionary objectForKey:@"threads"];
        
        for (NSDictionary *i in threadsArray) {
            Thread *thread = [[Thread alloc]init];
            thread.posts = [NSMutableArray array];
            NSDictionary *postDictionary = [[[i objectForKey:@"posts"] objectAtIndex:0] objectAtIndex:0];
            Post *post = [Post postWithDictionary:postDictionary andBoardId:self.boardId];
            post.threadReplies = [post makeThreadReplies:[[i objectForKey:@"reply_count"] intValue]];
            [thread.posts addObject:post];
            [self.threadsList addObject:thread];
        }

        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        });
    });
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
    return self.threadsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIndenifier"];
    
    [cell updateFonts];
    
    Thread *thread = self.threadsList[indexPath.row];
    Post *originalPost = [thread.posts objectAtIndex:0];
    
    [cell setPost:originalPost];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    cell.comment.delegate = self;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapped:)];
    tgr.delegate = self;
    [cell.postImage addGestureRecognizer:tgr];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ThreadTableViewCell *cell = [[ThreadTableViewCell alloc]init];
    
    Thread *thread = self.threadsList[indexPath.row];
    Post *originalPost = [thread.posts objectAtIndex:0];
    
    [cell setPost:originalPost];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    height += 1;
    
    return height;
    
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showThread" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; //have no idea why
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showThread"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        Thread *thread = self.threadsList[indexPath.row];
        Post *originalPost = [thread.posts objectAtIndex:0];
        NSString *threadId = [NSString stringWithFormat:@"%ld", (long)originalPost.num];
        NSString *subject = [NSString string];
        
        
        subject = [NSString stringWithFormat:@"Тред в %@", self.boardId];
        
        ThreadViewController *destination = segue.destinationViewController;
        
        destination.navigationItem.title = subject;
        
        [destination setBoardId:self.boardId];
        [destination setThreadId:threadId];
    }
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
        case boardThreadPostLink: {
            //проскроллить страницу
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            ThreadViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTag"];
            controller.boardId = urlNinja.boardId;
            controller.threadId = urlNinja.threadId;
            controller.postId = urlNinja.postId;
            [self.navigationController pushViewController:controller animated:YES];
            break;
            }
            break;
        default:
            //внешня ссылка - предложение открыть в сафари
            [[[UIActionSheet alloc] initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:NSLocalizedString(@"Отмена", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Открыть ссылку в Safari", nil), nil] showInView:self.view];
            break;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
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

- (void)refresh {
    [self.refreshControl endRefreshing];
    [self loadData];
}


@end