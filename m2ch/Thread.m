//
//  Thread.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Thread.h"

static NSInteger postsOnPage = 50;

@implementation Thread

- (id)initThreadWithThread:(Thread *)thread {
    self.posts = [NSMutableArray array];
    NSInteger i = 0;
    if (thread.posts.count > postsOnPage) {
        i = postsOnPage;
    } else {
        i = thread.posts.count;
    }
       
    for (int k = 0; k < i; k++) {
        [self.posts addObject:thread.posts[thread.posts.count-i+k]];
        [self.linksReference addObject:thread.linksReference[thread.posts.count-i+k]];
    }
    
    return self;
};

+ (id)currentThreadWithThread:(Thread *)thread {
    return [[self alloc]initThreadWithThread:thread];
};

- (Thread *)insertMorePostsFrom:(Thread *)thread {
    NSInteger currentThreadCount = self.posts.count;
    NSInteger sourceThreadCount = thread.posts.count;
    NSInteger i = 0;
    if ((sourceThreadCount - currentThreadCount) > postsOnPage) {
        i = postsOnPage;
    } else {
        i = sourceThreadCount - currentThreadCount;
    }
    
    self.updatedIndexes = [NSMutableArray array];
    
    for (int k = 0; k < i; k++) {
        [self.posts insertObject:thread.posts[sourceThreadCount-currentThreadCount-i+k] atIndex:k];
        [self.linksReference insertObject:thread.linksReference[sourceThreadCount-currentThreadCount-i+k] atIndex:k];
        NSIndexPath *index = [NSIndexPath indexPathForItem:k inSection:0];
        [self.updatedIndexes addObject:index];
    }
    return self;
};

@end
