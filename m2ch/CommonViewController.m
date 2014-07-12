//
//  CommonViewController.m
//  Tabula
//
//  Created by Alexander Tewpin on 03/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "CommonViewController.h"

#import "BoardViewController.h"
#import "ThreadViewController.h"
#import "PostViewController.h"

@interface CommonViewController ()

@end

@implementation CommonViewController



#pragma mark - Network

- (void)loadDataForUrl:(NSURL *)url isMainUrl:(BOOL)isMain {
    if (url) {
        [self updateStarted];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error && isMain == YES) {
                [self createDataWithLocation:location];
            } else if (!error && isMain == NO) {
                [self createChildDataWithLocation:location];
            } else {
                [self errorMessage];
            }
        }];
        [task resume];
    }
}

- (void)loadMorePosts {

}

- (void)createDataWithLocation:(NSURL *)location {
    
}

- (void)createChildDataWithLocation:(NSURL *)location {
    
}

- (void)errorMessage {
    self.isLoaded = YES;
    [self.spinner stopAnimating];
    
    UILabel *errorLabel = [[UILabel alloc]initWithFrame:self.view.frame];
    errorLabel.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2-self.navigationController.navigationBar.frame.size.height);
    errorLabel.text = @"Ошибка закралась в рассчеты";
    errorLabel.font = [UIFont systemFontOfSize:14];
    errorLabel.textColor = [UIColor grayColor];
    errorLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:errorLabel];
}

- (void)creationEnded {
    self.isLoaded = YES;
    [self.spinner stopAnimating];
}

- (void)updateStarted {
    self.isLoaded = NO;
}

- (void)updateEnded {
    self.isLoaded = YES;
    [self.spinner stopAnimating];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.color = [UIColor grayColor];
    self.spinner.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2 - self.navigationController.navigationBar.frame.size.height);
    self.spinner.hidesWhenStopped = YES;
    [self.spinner startAnimating];
    [self.view addSubview:self.spinner];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

#pragma mark - Links and Segues

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
            [self openThreadWithUrlNinja:urlNinja];
            break;
        }
        case boardThreadPostLink: {
            //если это этот же тред, то он открывается локально, оначе открывается вест тред со скроллом
            if ([self.threadId isEqualToString:urlNinja.threadId] && [self.boardId isEqualToString:urlNinja.boardId]) {
                if ([self.thread.linksReference containsObject:urlNinja.postId]) {
                    [self openPostWithUrlNinja:urlNinja];
                    return;
                }
            }
            [self openThreadWithUrlNinja:urlNinja];
        }
            break;
        default: {
            [self makeExternalLinkActionSheetWithUrl:url];
            break;
        }
    }
}

//Используется только когда открывается пост в том же треде (потенциал для рефакторинга)
- (void)openPostWithUrlNinja:(UrlNinja *)urlNinja {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    NSUInteger postNum = [self.thread.linksReference indexOfObject:urlNinja.postId];
    
    NSUInteger indexArray[] = {0, postNum};
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexArray length:2];
    Post *post = self.thread.posts[indexPath.row];
    PostViewController *destination = [storyboard instantiateViewControllerWithIdentifier:@"PostTag"];
    
    [destination setThread:self.thread];
    [destination setBoardId:self.boardId];
    [destination setThreadId:self.threadId];
    [destination setPostId:post.postId];
    [destination setReplyTo:post.replyTo];
    [destination setReplies:post.replies];
    
    [self.navigationController pushViewController:destination animated:YES];
}

- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ThreadViewController *destination = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTag"];
    [destination setBoardId:urlNinja.boardId];
    [destination setThreadId:urlNinja.threadId];
    [destination setPostId:urlNinja.postId];
    
    [self.navigationController pushViewController:destination animated:YES];
}

//изжить!
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"newPost"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        GetRequestViewController *destinationController = (GetRequestViewController *)navigationController.topViewController;
        [destinationController setBoardId:self.boardId];
        [destinationController setThreadId:self.threadId];
        [destinationController setDraft:self.thread.postDraft];
        destinationController.postView.text = self.thread.postDraft;
        //destinationController.delegate = self;
    }
}

#pragma mark - Action Sheets

- (void)makeExternalLinkActionSheetWithUrl:(NSURL *)url {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:[url absoluteString] delegate:nil cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:@"Открыть ссылку в Safari", nil];
    actionSheet.tag = 2;
    [actionSheet showInView:self.view];
}

- (void)makeWebmActionSheetWithUrl:(NSURL *)url {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:[url absoluteString] delegate:nil cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:@"Загрузить через Safari", nil];
    actionSheet.tag = 3;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 2) { //клик по ссылке
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        }
        //кстати, на конфе видел, что это хуевое решение, потому что юиаппликейнеш не должен за это отвечать и это как-то решается через делегирование
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
    } else if (actionSheet.tag == 3) { //webm-ссылка
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
    };
}

#pragma mark - Gesture Recognizers

- (void)imageTapped:(UITapGestureRecognizer *)sender {

    TapImageView *image = (TapImageView *)sender.view;
    
    if (image.bigImageUrl) {
        NSLog(@"%@", image.bigImageUrl.pathExtension);
        if ([image.bigImageUrl.pathExtension isEqualToString:@"webm"]) {
            [self makeWebmActionSheetWithUrl:image.bigImageUrl];
        } else {
        
        // Create image info
        JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
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
    }
}

#pragma mark - New Post Delegate

- (void)postCanceled:(NSString *)draft{
    self.thread.postDraft = draft;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postPosted {
    self.thread.postDraft = nil;
    [self loadMorePosts];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Post Height

- (CGFloat)heightForPost:(Post *)post {
    
    if (self == self.navigationController.topViewController) {
        
        if (post.postHeight) {
            return post.postHeight;
        } else {
            
            PostTableViewCell *cell = [[PostTableViewCell alloc]init];
            
            [cell setTextPost:post];
            
            [cell setNeedsUpdateConstraints];
            [cell updateConstraintsIfNeeded];
            
            cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(cell.bounds));
            
            [cell setNeedsLayout];
            [cell layoutIfNeeded];
            
            CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            
            height += 1;
            post.postHeight = height;
            
            return height;
        }
    }
    
    return 0;
}

@end
