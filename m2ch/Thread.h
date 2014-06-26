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

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *linksReference; //массив с номерами постов для ссылок
@property (nonatomic, strong) NSNumber *replyCount;

@property (nonatomic, strong) NSMutableArray *updatedIndexes;
@property (nonatomic, strong) NSString *postDraft; //хранит текст для недописанного поста
@property (nonatomic, strong) NSIndexPath *startingRow; //место с которого тред стартует при открытии
@property (nonatomic, strong) NSString *startingPost;

@property (nonatomic) NSUInteger postsTopLeft;
@property (nonatomic) NSUInteger postsBottomLeft;

- (Thread *)insertMoreTopPostsFrom:(Thread *)thread;
- (Thread *)insertMoreBottomPostsFrom:(Thread *)thread;

- (id)initThreadWithThread:(Thread *)thread andPosition:(NSIndexPath *)index;
+ (id)currentThreadWithThread:(Thread *)thread andPosition:(NSIndexPath *)index;

@end
