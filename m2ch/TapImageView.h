//
//  TapImageView.h
//  Tabula
//
//  Created by Alexander Tewpin on 10/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "AsyncImageView.h"

@interface TapImageView : AsyncImageView <UIGestureRecognizerDelegate>

@property (nonatomic) NSInteger tnHeight;
@property (nonatomic) NSInteger tnWidth;
@property (nonatomic, strong)NSURL *bigImageUrl;

@end
