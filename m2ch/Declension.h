//
//  Declensions.h
//  Tabula
//
//  Created by Alexander Tewpin on 22/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

// мини-класс для обработки склонений слов

#import <Foundation/Foundation.h>

@interface Declension : NSObject

@property (nonatomic, strong) NSString* output;

- (id) initWithPostCount:(NSUInteger)number;
+ (id) stringWithPostCount:(NSUInteger)number;

@end
