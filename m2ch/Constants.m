//
//  Constants.m
//  Tabula
//
//  Created by Alexander Tewpin on 06/08/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Constants.h"

@implementation Constants

+ (UIColor *)celestiaGreen {
    static UIColor *_celestiaGreen;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _celestiaGreen = [UIColor colorWithRed:(17/255.0) green:(139/255.0) blue:(116/255.0) alpha:1.0];
    });
    return _celestiaGreen;
}

+ (UIColor *)celestiaOrange {
    static UIColor *_celestiaOrange;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _celestiaOrange = [UIColor colorWithRed:(255/255.0) green:(139/255.0) blue:(16/255.0) alpha:1.0];
    });
    return _celestiaOrange;
}

+ (UIColor *)celestiaDarkGrey {
    static UIColor *_celestiaDarkGrey;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _celestiaDarkGrey = [UIColor colorWithRed:(155/255.0) green:(155/255.0) blue:(155/255.0) alpha:1.0];
    });
    return _celestiaDarkGrey;
}

+ (UIColor *)celestiaLightGrey {
    static UIColor *_celestiaLightGrey;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _celestiaLightGrey = [UIColor colorWithRed:(216/255.0) green:(216/255.0) blue:(216/255.0) alpha:1.0];
    });
    return _celestiaLightGrey;
}

+ (UIColor *)celestiaSeparatorGrey {
    static UIColor *_celestiaSeparatorGrey;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _celestiaSeparatorGrey = [UIColor colorWithRed:(216/255.0) green:(216/255.0) blue:(216/255.0) alpha:1.0];
    });
    return _celestiaSeparatorGrey;
}

@end
