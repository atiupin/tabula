//
//  GetRequestViewController.m
//  m2ch
//
//  Created by Александр Тюпин on 20/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "GetRequestViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>

NSString *const CAPTCHA_CF_WAIT = @"Обнаружена защита от DDoS, ждите...";
NSString *const CAPTCHA_DDOS_BROKEN = @"Похоже, что капча сломана защитой от DDoS";
NSString *const CAPTCHA_PLEASE_WAIT = @"Ждите...";
NSString *const CAPTCHA_EMPTY = @"";
NSString *const CAPTCHA_NOT_LOADING = @"Капча не загрузилась, попробуйте ещё раз...";

@interface GetRequestViewController ()

@property (nonatomic, strong) NSString *captchaKey;

@end

@implementation GetRequestViewController

#pragma mark - Core controller

- (void)viewDidLoad
{
    self.postView.textContainerInset = UIEdgeInsetsMake(10, 5, 5, 5);
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(self.loader.frame.size.width / 2, self.loader.frame.size.height / 2);
    [self.loader addSubview:spinner];
    [spinner startAnimating];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    //предварительная настройка лейблов
    self.sageStatus = NO;
    self.sageStatusButton.selected = NO;
    self.postView.text = self.draft;
    
    [self.postView becomeFirstResponder];

    [self viewPreparations];
    [self refreshCaptcha];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.timer invalidate];
}

- (void)viewPreparations {
    self.captchaView.hidden = NO;
    self.fixCaptcha.hidden = YES;
    self.captchaStatus.text = CAPTCHA_EMPTY;
}

#pragma mark - Captcha handling

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
            [self.loader removeFromSuperview];
        } else {
            self.captchaStatus.text = @"";
            [self.loader removeFromSuperview];
        }
    }
}

/**
 *  Actually - it's just getting captcha
 *  We can reload captcha by calling this method many times
 */
- (void)refreshCaptcha {
    
    AFHTTPSessionManager *captchaManager = [AFHTTPSessionManager manager];
    captchaManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [captchaManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"text/plain"]];
    
    NSString *captchaUrl = @"https://2ch.hk/makaba/captcha.fcgi";
    
    [captchaManager GET:captchaUrl parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSString *captchaKeyAnswer = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        if ([captchaKeyAnswer hasPrefix:@"CHECK"]) {
            NSArray *arrayOfCaptchaKeyAnswers = [captchaKeyAnswer componentsSeparatedByString: @"\n"];
            
            NSString *captchaKey = [arrayOfCaptchaKeyAnswers lastObject];
            
            /**
             *  Set var for requesting Yandex key image now and posting later.
             */
            _captchaKey = captchaKey;
            
            NSString *getcaptchaImageUrl = @"http://captcha.yandex.net/image?key=%@";
            
            NSString *urlOfYandexCaptchaImage = [[NSString alloc] initWithFormat:getcaptchaImageUrl,captchaKey];
            
            /**
             *  Present yandex captcha image to VC
             */
            [_captchaImage sd_setImageWithURL:[NSURL URLWithString:urlOfYandexCaptchaImage]];
            _captchaView.text = @"";
            
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)captchaBroken {
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

    NSString *comment = _postView.text;
    NSString *captchaValue = _captchaView.text;
    
    [self postMessageWithTask:@"post"
                     andBoard:_boardId
                 andThreadnum:_threadId
                      andName:@""
                     andEmail:@""
                   andSubject:@""
                   andComment:comment
                   andCaptcha:_captchaKey
              andcaptchaValue:captchaValue
     ];
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

/**
 *  Make post to thread
 *
 *  @param task         always POST
 *  @param board        board shortCode
 *  @param threadNum    we can use it for creating new posts or even new threads
 *  @param name         name of poster
 *  @param email        e-mail of poster and sage
 *  @param subject      sibject of the post
 *  @param comment      comment
 *  @param captchaKey   captcha key from Yandex
 *  @param captchaValue captcha value from our image (entered by user)
 */
- (void)postMessageWithTask:(NSString *)task
                   andBoard:(NSString *)board
               andThreadnum:(NSString *)threadNum
                    andName:(NSString *)name
                   andEmail:(NSString *)email
                 andSubject:(NSString *)subject
                 andComment:(NSString *)comment
                 andCaptcha:(NSString *)captchaKey
            andcaptchaValue:(NSString *)captchaValue
{
    
    self.navigationItem.rightBarButtonItem.enabled = FALSE;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSString *json = @"1";
    
    NSString *dvachBaseUrl = @"https://2ch.hk/";
    
    NSString *address = [[NSString alloc] initWithFormat:@"%@%@", dvachBaseUrl, @"makaba/posting.fcgi"];
    
    NSDictionary *params = @{
                             @"task":task,
                             @"json":json,
                             @"board":board,
                             @"thread":threadNum,
                             @"captcha":captchaKey,
                             @"captcha_value":captchaValue
                             };
    
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"application/json",nil]];
    
    [manager POST:address parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        // added comment field this way because makaba don't handle it wright if we pass it "normal" way
        // and name
        // and subject
        [formData appendPartWithFormData:[comment dataUsingEncoding:NSUTF8StringEncoding] name:@"comment"];
        [formData appendPartWithFormData:[name dataUsingEncoding:NSUTF8StringEncoding] name:@"name"];
        [formData appendPartWithFormData:[subject dataUsingEncoding:NSUTF8StringEncoding] name:@"subject"];
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        // NSLog(@"Success: %@", responseObject);
        
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"Success: %@", responseString);
        
        NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        
        // status field from response
        NSString *status = [responseDictionary objectForKey:@"Status"];
        
        //reason field from response
        NSString *reason = [responseDictionary objectForKey:@"Reason"];
        
        // if post was successful
        if (([status isEqualToString:@"OK"])||([status isEqualToString:@"Redirect"]))
        {
            NSString *successTitle = NSLocalizedString(@"Успешно", @"Title of the createPostVC when post was successfull");
            _captchaStatus.text = successTitle;
            
            /**
             *  We need to dismiss Controller here, go back to thread (and update it)
             */
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        
        /**
         *  If post wasn't successful.
         */
        else
        {
            /**
             *  Present alert with error code to user.
             */
            NSString *alertAboutPostTitle = NSLocalizedString(@"Ошибка", @"Alert Title of the createPostVC when post was NOT successful");
            
            UIAlertView *alertAboutPost = [[UIAlertView alloc] initWithTitle:alertAboutPostTitle message:reason delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertAboutPost setTag:0];
            [alertAboutPost show];
            self.navigationItem.rightBarButtonItem.enabled = TRUE;
            [self refreshCaptcha];
        }
        
    }
          failure:^(NSURLSessionDataTask *task, NSError *error)
    {
        
        NSString *cancelTitle = NSLocalizedString(@"Ошибка", @"Title of the createPostVC when post was NOT successful");
        _captchaStatus.text = cancelTitle;
        [self refreshCaptcha];
        NSLog(@"Error: %@", error);
    }];
}

@end
