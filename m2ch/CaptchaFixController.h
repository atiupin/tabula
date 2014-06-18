//
//  CaptchaFixController.h
//  Tabula
//
//  Created by Alexander Tewpin on 10/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CaptchaFixViewControllerDelegate

    - (void)captchaFixed;

@end

@interface CaptchaFixController : UIViewController <NSURLSessionDelegate>

@property (nonatomic, assign) id<CaptchaFixViewControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSURL *pageUrl;

@end