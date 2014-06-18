//
//  FooterView.m
//  Tabula
//
//  Created by Alexander Tewpin on 13/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "FooterView.h"

@implementation FooterView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.refreshButton.frame = CGRectMake(0, 0, 320, 44);
        [self.refreshButton setTitle:@"Обновить тред" forState:UIControlStateNormal];
        [self addSubview:self.refreshButton];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
