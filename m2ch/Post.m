//
//  Post.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Post.h"

#define kCommentFontSize        14.0f
#define kCommentLineSpacing     2.0f

@implementation Post

- (NSMutableArray *)replyTo {
    if (!_replyTo) {
        _replyTo = [NSMutableArray array];
    }
    return _replyTo;
}

- (NSMutableArray *)replies {
    if (!_replies) {
        _replies = [NSMutableArray array];
    }
    return _replies;
}

- (id) initWithDictionary:(NSDictionary *)source andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    
    self.boardId = boardId;
    self.threadId = threadId;
    
    NSString *stringUrl = [[@"http://2ch.hk/" stringByAppendingString:boardId] stringByAppendingString:@"/"];
    NSURL *boardUrl = [NSURL URLWithString:stringUrl];
    NSString *thumbnail = [source objectForKey:@"thumbnail"];
    NSString *image = [source objectForKey:@"image"];
    
    
    if (thumbnail != (id)[NSNull null] && thumbnail != nil) {
        self.thumbnailUrl = [NSURL URLWithString:thumbnail relativeToURL:boardUrl];
    }
    
    
    if (image != (id)[NSNull null] && image != nil) {
        self.imageUrl = [NSURL URLWithString:image relativeToURL:boardUrl];
    }
    
    NSNumber *tnWidth = [source objectForKey:@"tn_width"];
    
    if (tnWidth != (id)[NSNull null]) {
        self.tnWidth = [tnWidth intValue];
    }
    else {
        self.tnWidth = 0;
    }
    
    NSNumber *tnHeight = [source objectForKey:@"tn_height"];
    
    if (tnHeight != (id)[NSNull null]) {
        self.tnHeight = [tnHeight intValue];
    }
    else {
        self.tnHeight = 0;
    }
    
    NSNumber *imgWidth = [source objectForKey:@"width"];
    
    if (imgWidth != (id)[NSNull null]) {
        self.imgWidth = [imgWidth intValue];
    }
    else {
        self.imgWidth = 0;
    }
    
    NSNumber *imgHeight = [source objectForKey:@"height"];
    
    if (imgHeight != (id)[NSNull null]) {
        self.imgHeight = [imgHeight intValue];
    }
    else {
        self.imgHeight = 0;
    }
    
    NSNumber *num = [source objectForKey:@"num"];
    
    if (num != (id)[NSNull null]) {
        self.num = [num intValue];
        self.postId = [NSString stringWithFormat:@"%@", num];
    }
    else {
        self.num = 0;
        self.postId = nil;
    }
    
    self.sage = YES;
    
    self.lasthit = [source objectForKey:@"lasthit"];
    self.timestamp = [source objectForKey:@"timestamp"];
    self.parent = [source objectForKey:@"parent"];
    self.subject = [source objectForKey:@"subject"];
    self.name = [source objectForKey:@"name"];
    self.date = [source objectForKey:@"date"];
    
    self.subtitle = [NSString stringWithFormat:@"%@, %@", self.name, self.date];
    self.body = [self makeBody:[source objectForKey:@"comment"]];
    
    return self;
}

+ (id) postWithDictionary:(NSDictionary *)source andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    return [[self alloc]initWithDictionary:source andBoardId:boardId andThreadId:threadId];
}

+ (id) examplePost {
    NSDictionary *source = @{@"width": @267,
                             @"lasthit": @1368187765,
                             @"num": @23158,
                             @"banned": @0,
                             @"date": @"Втр 25 Дек 2012 20:04:11",
                             @"size": @25,
                             @"timestamp": @1356455051,
                             @"sticky": @2,
                             @"tn_width": @133,
                             @"closed": @0,
                             @"thumbnail": @"thumb/1356455051857s.gif",
                             @"parent": @0,
                             @"video": @"",
                             @"subject": @"FAQ-тред",
                             @"name": @"Аноним",
                             @"height": @400,
                             @"image": @"src/1356455051857.jpg",
                             @"tn_height": @200,
                             @"comment": @"<p>Тред для вопросов по дизайну&#44; которые недостойны отдельного треда.<br />Прошлый тред <a href=\"https://2ch.hk/de/res/6546.html\" rel=\"nofollow\">тонет там</a>&#44; <a href=\"https://googledrive.com/host/0B-8wdjrOS-4FUVNDcC05MExMUGc/de_6546/\" rel=\"nofollow\">сохранён здесь</a> .<br />Более полугода назад аноном был запилен сайт <a href=\"http://fromdewithlove.appspot.com/\" rel=\"nofollow\">DesignFAQ</a> на Google App Engine для <span class=\"s\">свалки</span> долговременного хранения ссылок и статей по дизайну. Предлагаю полезные материалы хранить там&#44; ибо треды не вечны.<br /><br />Предлагаю обсудить возможность создания по дизайну более или менее компактного набора советов&#44; как у <a href=\"http://www.2ch.hk/fiz_faq.htm\" rel=\"nofollow\">Физача</a> или <a href=\"http://2ch.hk/wh/faq.html\" rel=\"nofollow\">Вахача</a>.",
                             @"op": @0
                             };
    return [[self alloc]initWithDictionary:source];
}

- (NSString *) makeSubtile:(NSString *)name withDate:(NSDate *)date {
    return @"Title";
}

- (NSAttributedString *) makeBody:(NSString *)comment {
    
    //чистка исходника и посильная замена хтмл-литералов
    comment = [comment stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    comment = [comment stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
    comment = [comment stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#44;" withString:@","];
    
    NSRange range = NSMakeRange(0, comment.length);
    
    NSMutableAttributedString *maComment = [[NSMutableAttributedString alloc]initWithString:comment];
    [maComment addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:kCommentFontSize] range:range];
    
    NSMutableParagraphStyle *commentStyle = [[NSMutableParagraphStyle alloc]init];
//    commentStyle.lineSpacing = kCommentLineSpacing;
    [maComment addAttribute:NSParagraphStyleAttributeName value:commentStyle range:range];

    //em
    UIFont *emFont = [UIFont fontWithName:@"HelveticaNeue-Italic" size:kCommentFontSize];
    NSMutableArray *emRangeArray = [NSMutableArray array];
    NSRegularExpression *em = [[NSRegularExpression alloc]initWithPattern:@"<em[^>]*>(.*?)</em>" options:0 error:nil];
    [em enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:emFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [emRangeArray addObject:value];
    }];
    
    //strong
    UIFont *strongFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:kCommentFontSize];
    NSMutableArray *strongRangeArray = [NSMutableArray array];
    NSRegularExpression *strong = [[NSRegularExpression alloc]initWithPattern:@"<strong[^>]*>(.*?)</strong>" options:0 error:nil];
    [strong enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:strongFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [strongRangeArray addObject:value];
    }];
    
    //emstrong
    UIFont *emStrongFont = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:kCommentFontSize];
    for (NSValue *emRangeValue in emRangeArray) {
        //value to range
        NSRange emRange = [emRangeValue rangeValue];
        for (NSValue *strongRangeValue in strongRangeArray) {
            NSRange strongRange = [strongRangeValue rangeValue];
            NSRange emStrongRange = NSIntersectionRange(emRange, strongRange);
            if (emStrongRange.length != 0) {
                [maComment addAttribute:NSFontAttributeName value:emStrongFont range:emStrongRange];
            }
        }
    }
    
    //strike
    //не будет работать с tttattributedlabel, нужно переделывать ссылки и все такое
    NSRegularExpression *strike = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"s\">(.*?)</span>" options:0 error:nil];
    [strike enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:result.range];
    }];
    
    //spoiler
    UIColor *spoilerColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    NSRegularExpression *spoiler = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"spoiler\">(.*?)</span>" options:0 error:nil];
    [spoiler enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:spoilerColor range:result.range];
    }];
    
    //quote
    UIColor *quoteColor = [UIColor colorWithRed:(120/255.0) green:(153/255.0) blue:(2/255.0) alpha:1.0];
    NSRegularExpression *quote = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"unkfunc\">(.*?)</span>" options:0 error:nil];
    [quote enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:quoteColor range:result.range];
    }];
    
    //link
    UIColor *linkColor = [UIColor colorWithRed:(255/255.0) green:(102/255.0) blue:(0/255.0) alpha:1.0];
    NSRegularExpression *link = [[NSRegularExpression alloc]initWithPattern:@"<a[^>]*>(.*?)</a>" options:0 error:nil];
    NSRegularExpression *linkLink = [[NSRegularExpression alloc]initWithPattern:@"href=\"(.*?)\"" options:0 error:nil];

    [link enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
        NSString *fullLink = [comment substringWithRange:result.range];
        NSTextCheckingResult *linkLinkResult = [linkLink firstMatchInString:fullLink options:0 range:NSMakeRange(0, fullLink.length)];
        NSRange urlRange = NSMakeRange(linkLinkResult.range.location+6, linkLinkResult.range.length-7);
        NSString *urlString = [fullLink substringWithRange:urlRange];
        NSURL *url = [[NSURL alloc]initWithString:urlString];
        if (url) {
            UrlNinja *un = [UrlNinja unWithUrl:url];
            if ([un.boardId isEqualToString:self.boardId] && [un.threadId isEqualToString:self.threadId] && un.type == boardThreadPostLink) {
                [self.replyTo addObject:un.postId];
            }
            [maComment addAttribute:NSLinkAttributeName value:url range:result.range];
            [maComment addAttribute:NSForegroundColorAttributeName value:linkColor range:result.range];
            [maComment addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:result.range];
        }
    }];
    
    //находим все теги и сохраняем в массив
    NSMutableArray *tagArray = [NSMutableArray array];
    NSRegularExpression *tag = [[NSRegularExpression alloc]initWithPattern:@"<[^>]*>" options:0 error:nil];
    [tag enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [tagArray addObject:value];
    }];
    
    //вырезательный цикл
    int shift = 0;
    for (NSValue *rangeValue in tagArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= shift;
        [maComment deleteCharactersInRange:cutRange];
        shift += cutRange.length;
    }
    
    //добавляем заголовок поста, если он есть
    if (self.subject && ![self.subject isEqualToString:@""]) {
        
        self.subject = [self.subject stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        self.subject = [self.subject stringByReplacingOccurrencesOfString:@"&#44;" withString:@","];
        
        NSMutableAttributedString *maSubject = [[NSMutableAttributedString alloc]initWithString:[self.subject stringByAppendingString:@"\n"]];
        [maSubject addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0] range:NSMakeRange(0, maSubject.length)];
        [maSubject addAttribute:NSParagraphStyleAttributeName value:commentStyle range:NSMakeRange(0, maSubject.length)];
        
        [maComment insertAttributedString:maSubject atIndex:0];
    }
    
    //заменить хтмл-литералы на нормальные символы (раньше этого делать нельзя, сломается парсинг)
    [[maComment mutableString] replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    

    return maComment;
}

@end
