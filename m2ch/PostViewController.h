//
//  PostViewController.h
//  Tabula
//
//  Created by Alexander Tewpin on 02/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostTableViewCell.h"
#import "CommentTableViewCell.h"
#import "Thread.h"

@interface PostViewController : UITableViewController <TTTAttributedLabelDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSString *postId;

@property (nonatomic, strong) NSArray *replyTo;
@property (nonatomic, strong) NSArray *replies;

@property (nonatomic, strong) Thread *thread;
@property (nonatomic, strong) Thread *currentThread;

@end
