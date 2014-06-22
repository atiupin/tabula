//
//  Declensions.m
//  Tabula
//
//  Created by Alexander Tewpin on 22/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Declension.h"

@implementation Declension

- (id) initWithPostCount:(NSUInteger)number {
    if (number == 0) {
        self.output = [NSString stringWithFormat:@"0 постов"];
    } else {
        NSInteger mod = (int)number%100;
        if (mod>=11 && mod<=19) {
            self.output = [NSString stringWithFormat:@"%ld постов", (long)number];
        } else {
            mod = (int)number%10;
            switch (mod) {
                case 1:
                    self.output = [NSString stringWithFormat:@"%ld пост", (long)number];
                    break;
                    
                case 2:
                    self.output = [NSString stringWithFormat:@"%ld поста", (long)number];
                    break;
                    
                case 3:
                    self.output = [NSString stringWithFormat:@"%ld поста", (long)number];
                    break;
                    
                case 4:
                    self.output = [NSString stringWithFormat:@"%ld поста", (long)number];
                    break;
                    
                default:
                    self.output = [NSString stringWithFormat:@"%ld постов", (long)number];
                    break;
            }
        }
    }
    return self;
};

+ (id) stringWithPostCount:(NSUInteger)number {
    return [[self alloc]initWithPostCount:number];
};

@end
