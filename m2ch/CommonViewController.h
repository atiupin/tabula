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

@interface CommonViewController : UITableViewController <TTTAttributedLabelDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, NewPostControllerDelegate>

@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSString *postId;

@property (nonatomic, strong) Thread *thread;
@property (nonatomic, strong) Thread *currentThread;

- (void)imageTapped:(UITapGestureRecognizer *)sender;
- (CGFloat)heightForPost:(Post *)post;
- (void)loadUpdatedData;
- (void)openPostWithUN:(UrlNinja *)urlNinja;

@end
