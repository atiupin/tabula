//
//  ThreadViewController.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostTableViewCell.h"
#import "Thread.h"
#import "Post.h"
#import "GetRequestViewController.h"
#import "Declension.h"

@interface ThreadViewController : UITableViewController <TTTAttributedLabelDelegate, UIActionSheetDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate, UIGestureRecognizerDelegate, PostViewControllerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSString *postId;
@property (nonatomic, strong) Thread *thread;
@property (nonatomic, strong) Thread *currentThread;

@property (nonatomic, strong) NSString *reply;
@property (nonatomic, strong) NSString *quote;

@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic) BOOL isLoaded;
@property (nonatomic) BOOL isUpdating;

- (void)scrollToRowAnimated: (NSIndexPath *)index isAnimated:(BOOL)animated;

@end
