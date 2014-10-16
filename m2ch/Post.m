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

- (NSMutableArray *)mediaBox {
    if (!_mediaBox) {
        _mediaBox = [NSMutableArray array];
    }
    return _mediaBox;
}

- (id) initWithDictionary:(NSDictionary *)source andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    
    self.boardId = boardId;
    self.threadId = threadId;
    
    NSString *stringUrl = [NSString stringWithFormat:@"%@/%@/", ROOT_URL, boardId];
    NSURL *boardUrl = [NSURL URLWithString:stringUrl];
    
    if ([source objectForKey:@"files"]) {
        for (NSDictionary *mediaDictionary in [source objectForKey:@"files"]) {
            Media *media = [Media mediaWithDictionary:mediaDictionary andRootUrl:boardUrl];
            [self.mediaBox addObject:media];
        }
    } else {
        Media *media = [Media mediaWithDictionary:source andRootUrl:boardUrl];
        if (media.tnHeight > 0 && media.tnWidth > 0) {
            [self.mediaBox addObject:media];
        }
    }
    
    NSNumber *timestamp = [source objectForKey:@"timestamp"];
    
    if (timestamp != (id)[NSNull null]) {
        self.timestamp = [timestamp intValue];
    }
    else {
        self.timestamp = 0;
    }
    
    NSNumber *num = [source objectForKey:@"num"];
    
    if (num != (id)[NSNull null]) {
        self.postId = [NSString stringWithFormat:@"%@", num];
    }
    else {
        self.postId = nil;
    }
    
    self.sage = YES;
    
    self.lasthit = [source objectForKey:@"lasthit"];
    self.parent = [source objectForKey:@"parent"];
    self.subject = [source objectForKey:@"subject"];
    self.name = [source objectForKey:@"name"];
    self.tripcode = [source objectForKey:@"trip"];
    
    self.date = [DateFormatter dateFromTimestamp:self.timestamp];
    
    self.name = [Post clearName:self.name];
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

+ (NSString *)clearName:(NSString *)name {
    name = [name stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"&nbsp" withString:@" "]; //иногда отдается так
    name = [name stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    
    NSMutableArray *tagArray = [NSMutableArray array];
    NSRegularExpression *tag = [[NSRegularExpression alloc]initWithPattern:@"<[^>]*>" options:0 error:nil];
    [tag enumerateMatchesInString:name options:0 range:NSMakeRange(0, name.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [tagArray addObject:value];
    }];
    
    NSMutableString *mName = [name mutableCopy];
    
    int shift = 0;
    for (NSValue *rangeValue in tagArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= shift;
        [mName deleteCharactersInRange:cutRange];
        shift += cutRange.length;
    }
    
    return mName;
}

- (NSAttributedString *) makeBody:(NSString *)comment {
    
    //чистка исходника и посильная замена хтмл-литералов
    comment = [comment stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    //comment = [comment stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#44;" withString:@","];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#47;" withString:@"/"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#92;" withString:@"\\"];
    
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
    UIColor *quoteColor = [UIColor colorWithRed:(17/255.0) green:(139/255.0) blue:(116/255.0) alpha:1.0];
    NSRegularExpression *quote = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"unkfunc\">(.*?)</span>" options:0 error:nil];
    [quote enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:quoteColor range:result.range];
    }];
    
    //link
    UIColor *linkColor = [UIColor colorWithRed:(255/255.0) green:(102/255.0) blue:(0/255.0) alpha:1.0];
    NSRegularExpression *link = [[NSRegularExpression alloc]initWithPattern:@"<a[^>]*>(.*?)</a>" options:0 error:nil];
    NSRegularExpression *linkLink = [[NSRegularExpression alloc]initWithPattern:@"href=\"(.*?)\"" options:0 error:nil];
    NSRegularExpression *linkLinkTwo = [[NSRegularExpression alloc]initWithPattern:@"href='(.*?)'" options:0 error:nil];

    [link enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
        NSString *fullLink = [comment substringWithRange:result.range];
        NSTextCheckingResult *linkLinkResult = [linkLink firstMatchInString:fullLink options:0 range:NSMakeRange(0, fullLink.length)];
        NSTextCheckingResult *linkLinkTwoResult = [linkLinkTwo firstMatchInString:fullLink options:0 range:NSMakeRange(0, fullLink.length)];
        
        NSRange urlRange = NSMakeRange(0, 0);
        
        if (linkLinkResult.numberOfRanges != 0) {
            urlRange = NSMakeRange(linkLinkResult.range.location+6, linkLinkResult.range.length-7);
        } else if (linkLinkResult.numberOfRanges != 0) {
            urlRange = NSMakeRange(linkLinkTwoResult.range.location+6, linkLinkTwoResult.range.length-7);
        }
        
        if (urlRange.length != 0) {
            NSString *urlString = [fullLink substringWithRange:urlRange];
            urlString = [urlString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            NSURL *url = [[NSURL alloc]initWithString:urlString];
            if (url) {
                UrlNinja *un = [UrlNinja unWithUrl:url];
                if ([un.boardId isEqualToString:self.boardId] && [un.threadId isEqualToString:self.threadId] && un.type == boardThreadPostLink) {
                    if (![self.replyTo containsObject:un.postId]) {
                        [self.replyTo addObject:un.postId];
                    }
                }
                [maComment addAttribute:NSLinkAttributeName value:url range:result.range];
                [maComment addAttribute:NSForegroundColorAttributeName value:linkColor range:result.range];
                [maComment addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:result.range];
            }
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
    
    //чистим переводы строк в начале и конце
    NSRegularExpression *whitespaceStart = [[NSRegularExpression alloc]initWithPattern:@"^\\s\\s*" options:0 error:nil];
    NSTextCheckingResult *wsResult = [whitespaceStart firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:wsResult.range];
    
    NSRegularExpression *whitespaceEnd = [[NSRegularExpression alloc]initWithPattern:@"\\s\\s*$" options:0 error:nil];
    NSTextCheckingResult *weResult = [whitespaceEnd firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:weResult.range];
    
    //и пробелы в начале каждой строки
    NSMutableArray *whitespaceLineStartArray = [NSMutableArray array];
    NSRegularExpression *whitespaceLineStart = [[NSRegularExpression alloc]initWithPattern:@"^[\\t\\f\\p{Z}]+" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [whitespaceLineStart enumerateMatchesInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [whitespaceLineStartArray addObject:value];
    }];
    
    int whitespaceLineStartShift = 0;
    for (NSValue *rangeValue in whitespaceLineStartArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= whitespaceLineStartShift;
        [maComment deleteCharactersInRange:cutRange];
        whitespaceLineStartShift += cutRange.length;
    }
    
    //и двойные переводы
    NSMutableArray *whitespaceDoubleArray = [NSMutableArray array];
    NSRegularExpression *whitespaceDouble = [[NSRegularExpression alloc]initWithPattern:@"[\\n\\r]{3,}" options:0 error:nil];
    [whitespaceDouble enumerateMatchesInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [whitespaceDoubleArray addObject:value];
    }];
    
    int whitespaceDoubleShift = 0;
    for (NSValue *rangeValue in whitespaceDoubleArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= whitespaceDoubleShift;
        [maComment deleteCharactersInRange:cutRange];
        [maComment insertAttributedString:[[NSAttributedString alloc]initWithString:@"\n\n" attributes:nil] atIndex:cutRange.location];
        whitespaceDoubleShift += cutRange.length - 2;
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
