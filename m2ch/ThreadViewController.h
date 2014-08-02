//
//  ThreadViewController.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonThreadViewController.h"
#import "GetRequestViewController.h"

@interface ThreadViewController : CommonThreadViewController <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) UIButton *refreshButton;

- (IBAction)replyButton:(id)sender;
- (IBAction)showRepliesButton:(id)sender;

@end
