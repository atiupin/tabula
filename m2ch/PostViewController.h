//
//  PostViewController.h
//  Tabula
//
//  Created by Alexander Tewpin on 02/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonThreadViewController.h"

@interface PostViewController : CommonThreadViewController

@property (nonatomic, strong) NSArray *replyTo;
@property (nonatomic, strong) NSArray *replies;

- (IBAction)showRepliesButton:(id)sender;

@end
