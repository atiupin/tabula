//
//  Post.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrlNinja.h"
#import "DateFormatter.h"

@interface Post : NSObject

@property (nonatomic) CGFloat postHeight;

//записываются при генерации
@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSString *postId;

@property (nonatomic, strong) NSString *lasthit;
@property (nonatomic, strong) NSString *parent;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSString *tripcode;

@property (nonatomic, strong) NSURL *imageUrl;
@property (nonatomic, strong) NSURL *thumbnailUrl;
@property (nonatomic, strong) NSURL *postUrl;

@property (nonatomic) NSInteger timestamp;
@property (nonatomic) NSInteger tnHeight;
@property (nonatomic) NSInteger tnWidth;
@property (nonatomic) NSInteger imgHeight;
@property (nonatomic) NSInteger imgWidth;
@property (nonatomic) BOOL sage;

@property (nonatomic, strong) NSMutableArray *replyTo;

@property (nonatomic, strong) NSAttributedString *body;

//записываются извне
@property (nonatomic, strong) NSString *threadReplies;
@property (nonatomic, strong) NSString *threadNumber;

@property (nonatomic, strong) NSMutableArray *replies;

@property (nonatomic) NSInteger replyCount;
@property (nonatomic) NSInteger newReplies;

- (NSAttributedString *) makeBody:(NSString *)comment;

- (id) initWithDictionary:(NSDictionary *)source andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId ;
+ (id) postWithDictionary:(NSDictionary *)source andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId ;
+ (id) examplePost;

@end
