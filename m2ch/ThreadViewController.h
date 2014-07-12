//
//  ThreadViewController.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonViewController.h"
#import "GetRequestViewController.h"

@interface ThreadViewController : CommonViewController <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) NSString *reply;
@property (nonatomic, strong) NSString *quote;

@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end
