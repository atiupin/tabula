//
//  CaptchaFixController.m
//  Tabula
//
//  Created by Alexander Tewpin on 10/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "CaptchaFixController.h"

@interface CaptchaFixController ()

@end

@implementation CaptchaFixController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.topItem.title = @"Починка капчи";
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = done;
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:self.pageUrl];
    [self.webView loadRequest:urlRequest];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dismiss {
    [self.delegate captchaFixed];
}

@end
