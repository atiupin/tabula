//
//  Thread.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Thread.h"

static NSInteger postsOnPage = 35;

@implementation Thread

//создает тред из мастер-треда
- (id)initThreadWithThread:(Thread *)thread andPosition:(NSIndexPath *)index {
    self.posts = [NSMutableArray array];
    NSInteger i = 0;
    NSUInteger position = 0;
    
    if ([index indexAtPosition:1] >= thread.posts.count) {
        position = thread.posts.count - 1;
    } else {
        position = [index indexAtPosition:1];
    }
    
    //пророверка больше 50 постов до конца треда или нет
    if (thread.posts.count > position + postsOnPage) {
        //берем 50 постов с нужного места
        i = postsOnPage;
        for (int k = 0; k < i; k++) {
            [self.posts addObject:thread.posts[position+k]];
            [self.linksReference addObject:thread.linksReference[position+k]];
        }
        //и стартуем с начала таблицы
        NSUInteger indexArray[] = {0, 0};
        self.startingRow = [NSIndexPath indexPathWithIndexes:indexArray length:2];
        self.postsTopLeft = position;
        self.postsBottomLeft = thread.posts.count - position - postsOnPage;
    }
    
    else {
        //сколько вообще постов в треде?
        if (thread.posts.count > postsOnPage) {
            //если больше, то грузим последние 50
            i = postsOnPage;
            //и стартуем с исходной позиции с поправкой на последние 50 постов
            NSUInteger indexArray[] = {0, postsOnPage - thread.posts.count + position};
            self.startingRow = [NSIndexPath indexPathWithIndexes:indexArray length:2];
            self.postsTopLeft = thread.posts.count - postsOnPage;
            self.postsBottomLeft = 0;
        } else {
            //если меньше, то все, что есть
            i = thread.posts.count;
            //и тоже стартуем с исходной позиции
            NSUInteger indexArray[] = {0, position};
            self.startingRow = [NSIndexPath indexPathWithIndexes:indexArray length:2];
            self.postsTopLeft = 0;
            self.postsBottomLeft = 0;
        }
        for (int k = 0; k < i; k++) {
            [self.posts addObject:thread.posts[thread.posts.count-i+k]];
            [self.linksReference addObject:thread.linksReference[thread.posts.count-i+k]];
        }
    }
    
    return self;
};

+ (id)currentThreadWithThread:(Thread *)thread andPosition:(NSIndexPath *)index {
    return [[self alloc]initThreadWithThread:thread andPosition:index];
};

- (id)initWithData:(NSData *)data andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    self.boardId = boardId;
    self.threadId = threadId;
    
    NSError *dataError = nil;
    NSArray *dataArray = [NSArray array];
    
    //может прийти nil, если двач тупит, потом нужно написать обработку
    if (data) {
        dataArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];
        if (dataError) {
            NSLog(@"JSON Error: %@", dataError);
            return nil;
        }
    }
    
    self.posts = [NSMutableArray array];
    self.linksReference = [NSMutableArray array];
    
    for (NSDictionary *dic in dataArray) {
        Post *post = [Post postWithDictionary:dic andBoardId:boardId andThreadId:threadId];
        post.replies = [NSMutableArray array];
        [self.posts addObject:post];
        [self.linksReference addObject:[NSString stringWithFormat:@"%ld", (long)post.num]];
    }
    
    for (Post *post in self.posts) {
        for (NSString *replyTo in post.replyTo) {
            NSInteger index = [self.linksReference indexOfObject:replyTo];
            if (index != NSNotFound) {
                Post *reply = self.posts[index];
                [reply.replies addObject:[NSString stringWithFormat:@"%lu", (long)post.num]];
            }
        }
    }
    
    return self;
}

+ (id)threadWithData:(NSData *)data andBoardId:(NSString *)boardId andThreadId:(NSString *)threadId {
    return [[self alloc]initWithData:data andBoardId:boardId andThreadId:threadId];
};

- (id)initThreadWithThread:(Thread *)thread andReplyTo:(NSArray *)replyTo andReplies:(NSArray *)replies andPostId:(NSString *)postId {
    
    self.posts = [NSMutableArray array];
    self.linksReference = [NSMutableArray array];
    
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

//догружает посты из мастер-треда сверху
- (Thread *)insertMoreTopPostsFrom:(Thread *)thread {
    
    NSInteger i = 0;
    NSInteger spc = self.posts.count;
    
    if (self.postsTopLeft > postsOnPage) {
        i = postsOnPage;
    }
    else {
        i = self.postsTopLeft;
    }
    
    self.updatedIndexes = [NSMutableArray array];
    NSMutableArray *toInsert = [NSMutableArray array];
    
    for (int k = 0; k < i; k++) {
        [toInsert insertObject:thread.posts[thread.posts.count-spc-self.postsBottomLeft-i+k] atIndex:k];
        [self.linksReference insertObject:thread.linksReference[thread.posts.count-spc-self.postsBottomLeft-i+k] atIndex:k];
        NSIndexPath *index = [NSIndexPath indexPathForItem:k inSection:0];
        [self.updatedIndexes addObject:index];
    }
    [toInsert addObjectsFromArray:self.posts];
    self.posts = toInsert;
    self.postsTopLeft -= i;
    return self;
};

//догружает посты из мастер-треда снизу
- (Thread *)insertMoreBottomPostsFrom:(Thread *)thread {
    
    NSInteger i = 0;
    NSInteger spc = self.posts.count;
    
    if (self.postsBottomLeft > postsOnPage) {
        i = postsOnPage;
    }
    else {
        i = self.postsBottomLeft;
    }
    
    self.updatedIndexes = [NSMutableArray array];
    NSMutableArray *toInsert = [NSMutableArray array];
    
    for (int k = 0; k < i; k++) {
        [toInsert insertObject:thread.posts[self.postsTopLeft+spc+k] atIndex:k];
        [self.linksReference insertObject:thread.linksReference[self.postsTopLeft+spc+k] atIndex:spc+k];
        NSIndexPath *index = [NSIndexPath indexPathForItem:spc+k inSection:0];
        [self.updatedIndexes addObject:index];
    }
    
    [self.posts addObjectsFromArray:toInsert];
    self.postsBottomLeft -= i;
    return self;
};

@end
