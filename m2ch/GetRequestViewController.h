//
//  GetRequestViewController.h
//  m2ch
//
//  Created by Александр Тюпин on 20/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptchaFixController.h"

@protocol NewPostControllerDelegate

- (void)postCanceled:(NSString *)draft;
- (void)postPosted;

@end

@interface GetRequestViewController : UIViewController <UIWebViewDelegate, CaptchaFixViewControllerDelegate>

@property (nonatomic, assign) id<NewPostControllerDelegate> delegate;

@property (nonatomic, strong)NSString *boardId;
@property (nonatomic, strong)NSString *threadId;
@property (nonatomic, strong)NSURL *url;
@property (nonatomic, strong)NSString *draft;

@property (strong, nonatomic) IBOutlet UIWebView *output;
@property (strong, nonatomic) UIView *loader;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSString *lastPostId;
@property (nonatomic) BOOL sageStatus;

@property (strong, nonatomic) IBOutlet UITextView *postView;
@property (strong, nonatomic) IBOutlet UIImageView *captchaImage;
@property (strong, nonatomic) IBOutlet UITextField *captchaView;
@property (strong, nonatomic) IBOutlet UILabel *captchaStatus;
@property (strong, nonatomic) IBOutlet UIButton *sageStatusButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (strong, nonatomic) IBOutlet UIButton *fixCaptcha;

- (IBAction)fixCaptcha:(id)sender;
- (IBAction)switchSageStatus:(id)sender;
- (IBAction)sendPost:(id)sender;
- (IBAction)dismiss:(id)sender;

@end