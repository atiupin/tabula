//
//  ThreadTableView.m
//  Tabula
//
//  Created by Alexander Tewpin on 13/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "ThreadTableView.h"

@implementation ThreadTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
    
}

- (void)setContentSize:(CGSize)contentSize {
    // I don't want move the table view during its initial loading of content.
    // Малопонятный код с SO, который блочит скроллинг при подгрузке новых данных
    if (!CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        if (contentSize.height > self.contentSize.height) {
            CGPoint offset = self.contentOffset;
            offset.y += (contentSize.height - self.contentSize.height);
            self.contentOffset = offset;
        }
    }
    [super setContentSize:contentSize];
}

@end
