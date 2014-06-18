//
//  PostTableViewCell.h
//  m2ch
//
//  Created by Александр Тюпин on 18/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "TapImageView.h"

@interface PostTableViewCell : UITableViewCell

@property (nonatomic) NSInteger num;

@property (strong, nonatomic) UILabel *title;
@property (strong, nonatomic) UILabel *subtitle;
@property (strong, nonatomic) UILabel *status;
@property (strong, nonatomic) TTTAttributedLabel *comment;
@property (strong, nonatomic) TapImageView *postImage;

- (id) setPost:(Post *)post;
- (void)updateFonts;

@end
