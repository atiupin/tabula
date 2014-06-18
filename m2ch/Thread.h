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

@property (nonatomic, strong)NSMutableArray *posts;
@property (nonatomic, strong)NSMutableArray *linksReference;
@property (nonatomic, strong)NSNumber *replyCount;
@property (nonatomic, strong)NSMutableArray *updatedIndexes;
@property (nonatomic, strong)NSString *postDraft; //хранит текст для недописанного поста

- (Thread *)insertMorePostsFrom:(Thread *)thread;

- (id)initThreadWithThread:(Thread *)thread;
+ (id)currentThreadWithThread:(Thread *)thread;

@end
