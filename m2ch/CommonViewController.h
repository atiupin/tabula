//
//  CommonViewController.h
//  Tabula
//
//  Created by Alexander Tewpin on 03/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Board.h"
#import "Thread.h"
#import "Post.h"

#import "ThreadTableViewCell.h"
#import "PostTableViewCell.h"
#import "CommentTableViewCell.h"
#import "GetRequestViewController.h"

#import "JTSImageViewController.h"
#import "JTSImageInfo.h"
#import "ThreadData.h"
#import "UrlNinja.h"
#import "Declension.h"

static NSString *ROOT_URL = @"http://2ch.hk";

@interface CommonViewController : UITableViewController <TTTAttributedLabelDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, NewPostControllerDelegate>

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *errorLabel;

@property (nonatomic, strong) NSURL *mainUrl;
@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSString *postId;

@property (nonatomic, strong) Thread *thread;
@property (nonatomic, strong) Thread *currentThread;

@property (nonatomic) BOOL isLoaded;
@property (nonatomic) BOOL isUpdating;

- (void)loadDataForUrl:(NSURL *)url isMainUrl:(BOOL)isMain handleError:(BOOL)handleError;
- (void)loadMorePosts;
- (void)createDataWithLocation:(NSURL *)location;
- (void)createChildDataWithLocation:(NSURL *)location;
- (void)errorMessage:(NSError *)error;
- (void)creationEnded;
- (void)updateStarted;
- (void)updateEnded;

- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja;
- (void)openPostWithUrlNinja:(UrlNinja *)urlNinja;

- (CGFloat)heightForPost:(Post *)post;
- (void)imageTapped:(UITapGestureRecognizer *)sender;

@end
