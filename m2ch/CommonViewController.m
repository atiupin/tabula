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

- (NSTextStorage *)dummyStorage {
    if (!_dummyStorage) {
        _dummyStorage = [[NSTextStorage alloc]init];
        NSTextContainer *textContainer = [[NSTextContainer alloc]initWithSize:CGSizeMake(CELL_TEXT_VIEW_WIDTH, FLT_MAX)];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContainer];
        [_dummyStorage addLayoutManager:layoutManager];
    }
    return _dummyStorage;
}

#pragma mark - Network

- (void)loadDataForUrl:(NSURL *)url isMainUrl:(BOOL)isMain handleError:(BOOL)handleError {
    if (url) {
        [self updateStarted];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error && isMain == YES) {
                [self createDataWithLocation:location];
            } else if (!error && isMain == NO) {
                [self createChildDataWithLocation:location];
            } else if (handleError == YES) {
                [self performSelectorOnMainThread:@selector(errorMessage:) withObject:error waitUntilDone:NO];
            }
        }];
        [task resume];
    }
}

- (void)createDataWithLocation:(NSURL *)location {
    
}

- (void)createChildDataWithLocation:(NSURL *)location {
    
}

- (void)errorMessage:(NSError *)error {
    [self updateEnded];
    
    //ошибку показываем только если нет контента
    if ([self.thread.posts count] == 0) {
        self.errorLabel = [[UILabel alloc]initWithFrame:self.view.frame];
        self.errorLabel.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2-self.navigationController.navigationBar.frame.size.height);
        self.errorLabel.font = [UIFont systemFontOfSize:14];
        self.errorLabel.textColor = [UIColor grayColor];
        self.errorLabel.textAlignment = NSTextAlignmentCenter;
        self.errorLabel.numberOfLines = 0;
        
        if (error.code == NSURLErrorCannotFindHost) {
            self.errorLabel.text = @"Сайт не найден";
        } else if (error.code == NSURLErrorNotConnectedToInternet){
            self.errorLabel.text = @"Отсутствует подключение к интернету";
        } else if (error.code == NSURLErrorTimedOut) {
            self.errorLabel.text = @"Сайт не отвечает\nили подключение слишком слабое";
        } else if (error.code == -666){
            self.errorLabel.text = @"Тред не найден";
        } else {
            self.errorLabel.text = @"Ошибка закралась в рассчеты";
        }
        
        [self.view addSubview:self.errorLabel];
    }
}

- (void)creationEnded {
    self.isLoaded = YES;
    [self.errorLabel removeFromSuperview];
    [self.spinner stopAnimating];
    [self.refreshControl endRefreshing];
}

- (void)updateStarted {
    self.isLoaded = NO;
}

- (void)updateEnded {
    self.isLoaded = YES;
    [self.errorLabel removeFromSuperview];
    [self.spinner stopAnimating];
    [self.refreshControl endRefreshing];
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    UrlNinja *urlNinja = [UrlNinja unWithUrl:URL];
    
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
            //если это этот же тред, то он открывается локально, иначе открывается весь тред со скроллом
            if ([self.threadId isEqualToString:urlNinja.threadId] && [self.boardId isEqualToString:urlNinja.boardId]) {
                if ([self.thread.linksReference containsObject:urlNinja.postId]) {
                    [self openPostWithUrlNinja:urlNinja];
                    return NO;
                }
            }
            [self openThreadWithUrlNinja:urlNinja];
        }
            break;
        default: {
            [self makeExternalLinkActionSheetWithUrl:URL];
            break;
        }
    }
    return NO;
}

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

#pragma mark - Action Sheets

- (void)makeExternalLinkActionSheetWithUrl:(NSURL *)url {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:@"Открыть в Safari", @"Скопировать ссылку", nil];
    actionSheet.tag = 2;
    [actionSheet showInView:self.view];
}

- (void)makeWebmActionSheetWithUrl:(NSURL *)url {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:@"Загрузить через Safari", @"Скопировать ссылку", nil];
    actionSheet.tag = 3;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 2) { //клик по ссылке
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
        } else if (buttonIndex == 1) {
            UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
            pasteBoard.string = actionSheet.title;
        } else {
            return;
        }
    } else if (actionSheet.tag == 3) { //webm-ссылка
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
        } else if (buttonIndex == 1) {
            UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
            pasteBoard.string = actionSheet.title;
        } else {
            return;
        }
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

@end
