//
//  PostViewController.h
//  Tabula
//
//  Created by Alexander Tewpin on 02/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface PostViewController : CommonViewController

@property (nonatomic, strong) NSArray *replyTo;
@property (nonatomic, strong) NSArray *replies;

@end
