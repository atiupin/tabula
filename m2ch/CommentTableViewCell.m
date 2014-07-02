//
//  CommentTableViewCell.m
//  Tabula
//
//  Created by Alexander Tewpin on 02/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "CommentTableViewCell.h"

@implementation CommentTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = CGRectMake(0, 0, 320, 20);
        self.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        self.separatorInset = UIEdgeInsetsMake(0, 9999, 0, 0);
        self.userInteractionEnabled = NO;
        
        self.comment = [[UILabel alloc] initWithFrame:self.frame];
        self.comment.textAlignment = NSTextAlignmentCenter;
        self.comment.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        self.comment.font = [UIFont systemFontOfSize:12];
        [self addSubview:self.comment];
    }
    return self;
}

@end
