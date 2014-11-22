//
//  GetRequestViewController.m
//  m2ch
//
//  Created by Александр Тюпин on 20/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "GetRequestViewController.h"

NSString *const CAPTCHA_CF_WAIT = @"Обнаружена защита от DDoS, ждите...";
NSString *const CAPTCHA_DDOS_BROKEN = @"Похоже, что капча сломана защитой от DDoS";
NSString *const CAPTCHA_PLEASE_WAIT = @"Ждите...";
NSString *const CAPTCHA_EMPTY = @"";
NSString *const CAPTCHA_NOT_LOADING = @"Капча не загрузилась, попробуйте ещё раз...";

@interface GetRequestViewController ()

@end

@implementation GetRequestViewController

#pragma mark - Core controller

- (void)viewDidLoad
{
    self.loader = [[UIView alloc]initWithFrame:self.captchaImage.frame];
    self.loader.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    [self.view addSubview:self.loader];
    
    self.postView.textContainerInset = UIEdgeInsetsMake(10, 5, 5, 5);
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(self.loader.frame.size.width / 2, self.loader.frame.size.height / 2);
    [self.loader addSubview:spinner];
    [spinner startAnimating];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    //предварительная настройка лейблов
    self.postButton.enabled = NO;
    self.sageStatus = NO;
    self.sageStatusButton.selected = NO;
    self.refreshButton.enabled = NO;
    self.postView.text = self.draft;
    
    [self.postView becomeFirstResponder];

    [self viewPreparations];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.timer invalidate];
}

- (void)viewPreparations {
    self.captchaImage.hidden = NO;
    self.captchaView.hidden = NO;
    self.fixCaptcha.hidden = YES;
    self.captchaStatus.text = CAPTCHA_EMPTY;

    [self performSelectorInBackground:@selector(captchaRequest) withObject:nil];
}

#pragma mark - Captcha handling

- (void)captchaRequest {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/res/%@.html", ROOT_URL, self.boardId, self.threadId];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    
    self.url = url;
    self.output.delegate = self;
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    //очистка куки, бывает нужно для тестов
//    NSHTTPCookie *cookie;
//    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    for (cookie in [storage cookies]) {
//        [storage deleteCookie:cookie];
//    }
//    [[NSUserDefaults standardUserDefaults] synchronize];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode == 503 && [[headers objectForKey:@"Server"] isEqualToString:@"cloudflare-nginx"]) {
            self.output.delegate = self;
            [self.output loadRequest:request];
        } else {
            NSMutableString *source = [[NSMutableString alloc] initWithContentsOfURL:location encoding:NSUTF8StringEncoding error:nil];
            [self clearSource:source];
        }
    }];
    [task resume];
}

- (void)clearSource:(NSMutableString *)source {
    if (source) {
        NSRegularExpression *css = [[NSRegularExpression alloc]initWithPattern:@"<link[^>]*text\\/css[^>]*>" options:0 error:nil];
        NSRegularExpression *images = [[NSRegularExpression alloc]initWithPattern:@"<img[^>]*src[^>]*>" options:0 error:nil];
        
        NSRange range = NSMakeRange(0, source.length);
        
        [css enumerateMatchesInString:source options:0 range:range usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
            [source deleteCharactersInRange:result.range];
        }];
        
        range = NSMakeRange(0, source.length);
        
        [images enumerateMatchesInString:source options:0 range:range usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
            [source deleteCharactersInRange:result.range];
        }];
    }
    [self.output loadHTMLString:source baseURL:self.url];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSString *html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
    self.refreshButton.enabled = NO;
    if ([html rangeOfString:@"TopNormalReply"].location != NSNotFound) {
        if ([self.captchaStatus.text isEqualToString:CAPTCHA_CF_WAIT] || [self.captchaStatus.text isEqualToString:CAPTCHA_DDOS_BROKEN]) {
            self.captchaStatus.text = CAPTCHA_EMPTY;
        }
        [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('TopNormalReplyLabel').click();"];
        self.loadStatusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkLoadStatus) userInfo:nil repeats:YES];
    } else if ([html rangeOfString:@"<p data-translate=\"process_is_automatic\">"].location != NSNotFound){
        self.captchaStatus.text = CAPTCHA_CF_WAIT;
        //обнаружен CF и будет редирект через 5 секунд
    } else {
        [self captchaBroken];
        //капча сломана намертво
    }
}

-(void) checkLoadStatus
{
    NSString *evalString = [self.output stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    if([evalString isEqualToString:@"complete"])
    {
        //Страница загрузилась - останавливаем таймер
        [self.loadStatusCheckTimer invalidate];
        self.loadStatusCheckTimer = nil;
        NSString *captchaString = [self.output stringByEvaluatingJavaScriptFromString: @"document.getElementsByClassName('captcha-image captcha-reload-button')[0].getElementsByTagName('img')[0].src;"];
        if ([captchaString isEqualToString:@""]) {
            self.captchaStatus.text = CAPTCHA_NOT_LOADING;
            self.refreshButton.enabled = YES;
            [self.loader removeFromSuperview];
        } else {
            NSURL *url = [[NSURL alloc] initWithString:captchaString];
            NSData *captchaData = [[NSData alloc] initWithContentsOfURL:url];
            self.captchaImage.image = [[UIImage alloc] initWithData:captchaData];
            self.captchaImage.hidden = NO;
            self.captchaStatus.text = @"";
            [self.loader removeFromSuperview];
            self.postButton.enabled = YES;
            self.refreshButton.enabled = YES;
        }
    }
}

- (void)refreshCaptcha {
    self.refreshButton.enabled = NO;
    self.postButton.enabled = NO;
    self.captchaImage.hidden = YES;
    [self.view addSubview:self.loader];
    self.captchaView.text = @"";
    [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('captcha-image captcha-reload-button')[0].click();"];
    self.loadStatusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkLoadStatus) userInfo:nil repeats:YES];
}

- (void)captchaBroken {
    self.captchaImage.hidden = YES;
    self.captchaView.hidden = YES;
    self.fixCaptcha.hidden = NO;
    self.captchaStatus.text = CAPTCHA_DDOS_BROKEN;
    self.loader.hidden = YES;
}

#pragma mark - Post controls

- (IBAction)switchSageStatus:(id)sender {
    if (self.sageStatus == NO) {
        self.sageStatus = YES;
        self.sageStatusButton.selected = YES;
    }
    else {
        self.sageStatus = NO;
        self.sageStatusButton.selected = NO;
    }
}

#pragma mark - Post sending

- (IBAction)sendPost:(id)sender {
    //получение id последнего поста
    self.lastPostId = [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('post')[document.getElementsByClassName('post').length-1].id"];
    
    //вставка поста в форму
    NSString *postText = [self.postView.text stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    postText = [postText stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    postText = [postText stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    NSString *postJs = [[@"document.getElementById('shampoo').value = '" stringByAppendingString:postText] stringByAppendingString:@"'"];
    [self.output stringByEvaluatingJavaScriptFromString:postJs];
    
    //вставка капчи в форму
    NSString *captchaJs = [[@"document.getElementsByName('captcha_value_id_06')[0].value = '" stringByAppendingString:self.captchaView.text] stringByAppendingString:@"'"];
    [self.output stringByEvaluatingJavaScriptFromString:captchaJs];
    
    //вставка сажи (железобетонный вариант, на случай куков на чекбоксе)
    if (self.sageStatus == YES) {
        [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('e-mail').value = 'sage'"];
        [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('sagecheckbox').checked = true"];
    }
    else {
        [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('e-mail').value = ''"];
        [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('sagecheckbox').checked = false"];
    }
    
    //установка таймера для проверки окна абустатуса
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(abuStatusChecker) userInfo:nil repeats:YES];
    [self.timer fire];
    
    //клик по кнопке отправить (submit() не работает)
    [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('submit').click();"];
    
    //document.getElementsByClassName('post')[document.getElementsByClassName('post').length-1].id
}

- (void)abuStatusChecker {
    
    NSString *abuAlert = [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('ABU_alert').firstChild.innerHTML"];
    
    NSString *abuAlertWait = [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementById('ABU_alert_wait').innerHTML"];
    
    NSString *lastPostId = [self.output stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('post')[document.getElementsByClassName('post').length-1].id"];
    
    if (![abuAlert isEqualToString:@""]) {
        self.captchaStatus.text = abuAlert;
    } else if (![abuAlertWait isEqualToString:@""]) {
        self.captchaStatus.text = CAPTCHA_PLEASE_WAIT;
    } else {
        self.captchaStatus.text = CAPTCHA_EMPTY;
    }
    
    if (![self.lastPostId isEqualToString:lastPostId]) {
        [self.timer invalidate];
        [self postPosted];
    }
    
}

- (void)postPosted {
    [self.delegate postPosted];
}

#pragma mark - Post cancel

- (void)postCanceled:(NSString *)draft {
    [self.output stopLoading];
    [self.delegate postCanceled:self.postView.text];
}

#pragma mark - CF fixation

- (IBAction)fixCaptcha:(id)sender {
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    CaptchaFixController *destinationController = [[CaptchaFixController alloc]initWithNibName:@"CaptchaFixController" bundle:nil];
    [navigationController addChildViewController:destinationController];
    [destinationController setPageUrl:self.url];
    destinationController.delegate = self;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)captchaFixed {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self viewPreparations];
}

#pragma mark - Other helper methods

- (IBAction)dismiss:(id)sender {
    [self postCanceled:self.postView.text];
}

- (IBAction)refreshButtonPressed:(id)sender {
    [self refreshCaptcha];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
//вычисление высоты клавиатуры и подравнивание всего, вернусь когда буду пилить верстку под старые айфоны
//    CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
//    CGFloat textHeight = self.view.frame.size.height - keyboardHeight;
//    CGRect postRect = CGRectMake(self.postView.frame.origin.x, self.postView.frame.origin.y, self.postView.frame.size.width, textHeight);
//    self.postView.frame = postRect;
}
@end
