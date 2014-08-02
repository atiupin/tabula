//
//  CTTextView.h
//  Tabula
//
//  Created by Alexander Tewpin on 23/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CTTextViewDelegate;

@interface CTTextView : UITextView

@property (nonatomic, weak) id<CTTextViewDelegate> ctDelegate;

@end

@protocol CTTextViewDelegate <NSObject>

@optional

- (void)CTTextViewWasTapped:(CTTextView *)ctTextView;

@end