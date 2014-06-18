//
//  Post.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Post : NSObject

@property (nonatomic) CGFloat postHeight;

@property (nonatomic, strong)NSString *lasthit;
@property (nonatomic, strong)NSString *timestamp;
@property (nonatomic, strong)NSString *parent;
@property (nonatomic, strong)NSString *subject;
@property (nonatomic, strong)NSString *name;
@property (nonatomic, strong)NSString *date;
@property (nonatomic, strong)NSString *threadReplies;

@property (nonatomic, strong)NSURL *imageUrl;
@property (nonatomic, strong)NSURL *thumbnailUrl;
@property (nonatomic, strong)NSURL *postUrl;

@property (nonatomic) NSInteger num;
@property (nonatomic) NSInteger replyCount;
@property (nonatomic) NSInteger tnHeight;
@property (nonatomic) NSInteger tnWidth;
@property (nonatomic) NSInteger imgHeight;
@property (nonatomic) NSInteger imgWidth;
@property (nonatomic) BOOL sage;

@property (nonatomic, strong) NSString *postTitle;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSAttributedString *body;

- (NSAttributedString *) makeBody:(NSString *)comment;
- (NSString *)makeSubtile:(NSString *)name withDate:(NSDate *)date;
- (NSString *)makeThreadReplies:(NSInteger)count;

- (id) initWithDictionary:(NSDictionary *)source andBoardId:(NSString *)boardId;
+ (id) postWithDictionary:(NSDictionary *)source andBoardId:(NSString *)boardId;
+ (id) examplePost;

@end
