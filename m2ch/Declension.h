//
//  Declensions.h
//  Tabula
//
//  Created by Alexander Tewpin on 22/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

// Класс для обработки склонений слов

#import <Foundation/Foundation.h>

@interface Declension : NSObject

@property (nonatomic, strong) NSString* output;

- (id) initWithAnswerCount:(NSInteger)number andNewPosts:(NSInteger)newnumber;
+ (id) stringWithAnswerCount:(NSInteger)number andNewPosts:(NSInteger)newnumber;

- (id) initWithPostCount:(NSUInteger)number;
+ (id) stringWithPostCount:(NSUInteger)number;

@end
