//
//  BoardViewController.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThreadTableViewCell.h"
#import "Post.h"
#import "Thread.h"

@interface BoardViewController : UITableViewController <TTTAttributedLabelDelegate, UIActionSheetDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSMutableArray *threadsList;
@property (nonatomic, strong) ThreadTableViewCell *threadCell;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end
