//
//  Declensions.m
//  Tabula
//
//  Created by Alexander Tewpin on 22/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Declension.h"

@implementation Declension

- (id) initWithAnswerCount:(NSInteger)number andNewPosts:(NSInteger)newnumber {
    if (number == 0 && newnumber > 0) {
        self.output = [NSString stringWithFormat:@"● %@", [self decPost:newnumber]];
    } else if (number > 0 && newnumber == 0) {
        self.output = [self decPost:number];
    } else if (number > 0 && newnumber > 0) {
        self.output = [NSString stringWithFormat:@"● %@ (+%ld)", [self decPost:number], (long)newnumber];
    } else {
        self.output = [NSString stringWithFormat:@"● %@", [self decPost:number]];
    }
    return self;
}

- (NSString *) decPost:(NSInteger)number {
    NSString *output = [NSString string];
    if (number == 0) {
        output = [NSString stringWithFormat:@"Нет постов"];
    } else {
        NSInteger mod = (int)number%100;
        if (mod>=11 && mod<=19) {
            output = [NSString stringWithFormat:@"%ld постов", (long)number];
        } else {
            mod = (int)number%10;
            switch (mod) {
                case 1:
                    output = [NSString stringWithFormat:@"%ld пост", (long)number];
                    break;
                    
                case 2:
                    output = [NSString stringWithFormat:@"%ld поста", (long)number];
                    break;
                    
                case 3:
                    output = [NSString stringWithFormat:@"%ld поста", (long)number];
                    break;
                    
                case 4:
                    output = [NSString stringWithFormat:@"%ld поста", (long)number];
                    break;
                    
                default:
                    output = [NSString stringWithFormat:@"%ld постов", (long)number];
                    break;
            }
        }
    }
    return output;
}

+ (id) stringWithAnswerCount:(NSInteger)number andNewPosts:(NSInteger)newnumber {
    return [[self alloc]initWithAnswerCount:number andNewPosts:newnumber];
}

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
