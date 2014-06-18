//
//  DebugController.h
//  m2ch
//
//  Created by Александр Тюпин on 29/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DebugController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *type;
@property (strong, nonatomic) IBOutlet UILabel *board;
@property (strong, nonatomic) IBOutlet UILabel *thread;
@property (strong, nonatomic) IBOutlet UILabel *post;
@property (strong, nonatomic) IBOutlet UILabel *source;

@end
