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

@property (nonatomic, weak) id<NewPostControllerDelegate> delegate;

@property (nonatomic, strong)NSString *boardId;
@property (nonatomic, strong)NSString *threadId;
@property (nonatomic, strong)NSURL *url;
@property (nonatomic, strong)NSString *draft;

@property (weak, nonatomic) IBOutlet UIWebView *output;
@property (strong, nonatomic) UIView *loader;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSString *lastPostId;
@property (nonatomic) BOOL sageStatus;
@property (strong, nonatomic) IBOutlet UIButton *refreshButton;

@property (weak, nonatomic) IBOutlet UITextView *postView;
@property (weak, nonatomic) IBOutlet UIImageView *captchaImage;
@property (weak, nonatomic) IBOutlet UITextField *captchaView;
@property (weak, nonatomic) IBOutlet UILabel *captchaStatus;
@property (weak, nonatomic) IBOutlet UIButton *sageStatusButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet UIButton *fixCaptcha;

- (IBAction)fixCaptcha:(id)sender;
- (IBAction)switchSageStatus:(id)sender;
- (IBAction)sendPost:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)refreshButtonPressed:(id)sender;

@end