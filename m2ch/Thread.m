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
            self.postsTopLeft = thread.posts.count - 50;
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
    
    for (int k = 0; k < i; k++) {
        [self.posts insertObject:thread.posts[thread.posts.count-spc-self.postsBottomLeft-i+k] atIndex:k];
        [self.linksReference insertObject:thread.linksReference[thread.posts.count-spc-self.postsBottomLeft-i+k] atIndex:k];
        NSIndexPath *index = [NSIndexPath indexPathForItem:k inSection:0];
        [self.updatedIndexes addObject:index];
    }
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
    
    for (int k = 0; k < i; k++) {
        [self.posts insertObject:thread.posts[self.postsTopLeft+spc+k] atIndex:spc+k];
        [self.linksReference insertObject:thread.linksReference[self.postsTopLeft+spc+k] atIndex:spc+k];
        NSIndexPath *index = [NSIndexPath indexPathForItem:spc+k inSection:0];
        [self.updatedIndexes addObject:index];
    }
    self.postsBottomLeft -= i;
    return self;
};

@end
