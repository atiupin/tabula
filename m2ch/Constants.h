//
//  Constants.h
//  Tabula
//
//  Created by Alexander Tewpin on 21/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const ROOT_URL = @"https://2ch.hk";

//магические числа для верстки ячейки с постом
static CGFloat const CELL_H_MINUS_TEXT = 61.0;
static CGFloat const CELL_TEXT_VIEW_V_INSET = 12.0;
static CGFloat const CELL_TEXT_VIEW_WIDTH = 300.0;
static CGFloat const CELL_IMAGE_BOX_SIZE_PX = 150.0;
static CGFloat const CELL_MEDIA_BOX_SIZE_PX = 130.0;
static CGFloat const CELL_IMAGE_V_INSET = 5.0;
static CGFloat const CELL_IMAGE_H_INSET = 10.0;

static CGFloat const COMMENT_FONT_SIZE = 14.0;
static CGFloat const COMMENT_LINE_SPACING = 2.0;

@interface Constants : NSObject

+ (NSArray *)makabaBoards;

+ (UIColor *)celestiaGreen;
+ (UIColor *)celestiaOrange;
+ (UIColor *)celestiaDarkGrey;
+ (UIColor *)celestiaLightGrey;
+ (UIColor *)celestiaSeparatorGrey;

@end