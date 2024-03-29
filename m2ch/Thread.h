//
//  Thread.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"

@interface Thread : NSObject

@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *threadId;

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *linksReference; //of NSSrings
@property (nonatomic, strong) NSNumber *replyCount;

@property (nonatomic, strong) NSString *postDraft; //хранит текст для недописанного поста
@property (nonatomic, strong) NSIndexPath *startingRow; //место с которого тред стартует при открытии
@property (nonatomic, strong) NSString *startingPost;

- (void)updateReplies;
- (void)updatePostIndexes;
- (void)updateDates;

- (id)initWithData:(NSData *)data andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId;
+ (id)threadWithData:(NSData *)data andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId;

- (id)initThreadWithThread:(Thread *)thread andReplyTo:(NSArray *)replyTo andReplies:(NSArray *)replies andPostId:(NSString *)postId;
+ (id)currentThreadWithThread:(Thread *)thread andReplyTo:(NSArray *)replyTo andReplies:(NSArray *)replies andPostId:(NSString *)postId;

@end
