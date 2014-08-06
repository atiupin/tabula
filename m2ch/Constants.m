//
//  Constants.m
//  Tabula
//
//  Created by Alexander Tewpin on 06/08/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Constants.h"

@implementation Constants

+ (NSArray *)makabaBoards {
    static NSArray *_makabaBoards;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _makabaBoards = @[@"b",
                          @"po",
                          @"vg",
                          @"test"];
    });
    return _makabaBoards;
}

@end
