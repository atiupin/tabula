//
//  Thread.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Thread.h"

@implementation Thread

#pragma mark - Safe Properties Getters

- (NSMutableArray *)posts {
    if (!_posts) {
        _posts = [NSMutableArray array];
    }
    return _posts;
}

- (NSMutableArray *)linksReference {
    if (!_linksReference) {
        _linksReference = [NSMutableArray array];
    }
    return _linksReference;
}

#pragma mark - Inits


- (id)initWithData:(NSData *)data andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    self.boardId = boardId;
    self.threadId = threadId;
    
    NSError *dataError = nil;
    
    if (data) {
        id dataArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];
        if (dataError) {
            return nil;
        }
        if ([dataArray isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dic in dataArray) {
                Post *post = [Post postWithDictionary:dic andBoardId:boardId andThreadId:threadId];

                [self.posts addObject:post];
                [self.linksReference addObject:post.postId];
            }
        } else {
            //ошибки приходят как nsdictionary
            //неплохо бы сделать нормальный возврат ошибок
            return nil;
        }
    }
    
    [self updatePostIndexes];
    [self updateReplies];
    [self updateDates];
    
    return self;
}

+ (id)threadWithData:(NSData *)data andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    return [[self alloc]initWithData:data andBoardId:boardId andThreadId:threadId];
};

- (id)initThreadWithThread:(Thread *)thread andReplyTo:(NSArray *)replyTo andReplies:(NSArray *)replies andPostId:(NSString *)postId {
    
    for (NSString *replyToId in replyTo) {
        [self.posts addObject:thread.posts[[thread.linksReference indexOfObject:replyToId]]];
        [self.linksReference addObject:replyToId];
    }
    
    [self.posts addObject:thread.posts[[thread.linksReference indexOfObject:postId]]];
    [self.linksReference addObject:postId];
    
    for (NSString *replyId in replies) {
        [self.posts addObject:thread.posts[[thread.linksReference indexOfObject:replyId]]];
        [self.linksReference addObject:replyId];
    }

    return self;
}

+ (id)currentThreadWithThread:(Thread *)thread andReplyTo:(NSArray *)replyTo andReplies:(NSArray *)replies andPostId:(NSString *)postId {
    return [[Thread alloc]initThreadWithThread:thread andReplyTo:replyTo andReplies:replies andPostId:postId];
}

#pragma mark - Thread update

- (void)updateReplies {
    for (Post *post in self.posts) {
        post.replies = nil;
    }
    for (Post *post in self.posts) {
        for (NSString *replyTo in post.replyTo) {
            NSInteger index = [self.linksReference indexOfObject:replyTo];
            if (index != NSNotFound) {
                Post *reply = self.posts[index];
                [reply.replies addObject:post.postId];
            }
        }
    }
}

- (void)updatePostIndexes {
    for (Post *post in self.posts) {
        NSInteger postIndex = [self.posts indexOfObject:post];
        post.threadNumber = [NSString stringWithFormat:@"%lu", (long)postIndex+1];
    }
}

- (void)updateDates {
    for (Post *post in self.posts) {
        post.date = [DateFormatter dateFromTimestamp:post.timestamp];
    }
}

@end
