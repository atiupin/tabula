//
//  CTTextView.m
//  Tabula
//
//  Created by Alexander Tewpin on 23/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "CTTextView.h"

@implementation CTTextView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.selectedRange.length == 0 && [_ctDelegate respondsToSelector:@selector(CTTextViewWasTapped:)]) {
        [_ctDelegate CTTextViewWasTapped:self];
    }
}

@end
