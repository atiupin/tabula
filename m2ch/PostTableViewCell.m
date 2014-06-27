//
//  PostTableViewCell.m
//  m2ch
//
//  Created by Александр Тюпин on 18/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "PostTableViewCell.h"

#define kLabelHorizontalInsets      15.0f
#define kLabelVerticalInsets        10.0f

@interface PostTableViewCell ()

@property (nonatomic, assign) BOOL didSetupConstraints;

@end

@implementation PostTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.title = [UILabel newAutoLayoutView];
        [self.title setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.title setNumberOfLines:1];
        [self.title setTextAlignment:NSTextAlignmentLeft];
        [self.title setTextColor:[UIColor blackColor]];
        
        self.subtitle = [UILabel newAutoLayoutView];
        [self.subtitle setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.subtitle setNumberOfLines:1];
        [self.subtitle setTextAlignment:NSTextAlignmentLeft];
        [self.subtitle setTextColor:[UIColor blackColor]];
        
        self.status = [UILabel newAutoLayoutView];
        [self.status setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.status setNumberOfLines:1];
        [self.status setTextAlignment:NSTextAlignmentRight];
        [self.status setTextColor:[UIColor blackColor]];
        
        self.comment = [TTTAttributedLabel newAutoLayoutView];
        [self.comment setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.comment setNumberOfLines:0];
        [self.comment setTextAlignment:NSTextAlignmentLeft];
        
        //приходится оверрайтить тут из-за особенностей tttattributedlabel
        self.comment.linkAttributes = @{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleNone]};
        self.comment.activeLinkAttributes = @{NSForegroundColorAttributeName:[UIColor colorWithRed:(170/255.0) green:(51/255.0) blue:(0/255.0) alpha:1.0]};
        
        self.postImage = [TapImageView newAutoLayoutView];
        
        [self.contentView addSubview:self.title];
        [self.contentView addSubview:self.subtitle];
        [self.contentView addSubview:self.status];
        [self.contentView addSubview:self.comment];
        [self.contentView addSubview:self.postImage];
        
//        self.selectionStyle = UITableViewCellSelectionStyleNone; //это убивает анимацию, отстой
        
        [self updateFonts];
    }
    return self;
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (self.didSetupConstraints) {
        return;
    }
    
    //title
    [UIView autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.title autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
    }];
    [self.title autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:kLabelVerticalInsets];
    [self.title autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:kLabelHorizontalInsets];
    
    //subtitle
    [UIView autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.subtitle autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
    }];
    [self.subtitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.title withOffset:0.0 relation:NSLayoutRelationEqual];
    [self.subtitle autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:kLabelHorizontalInsets];
    
    //status
    [UIView autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.status autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
    }];
    [self.status autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:kLabelVerticalInsets];
    [self.status autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.title withOffset:kLabelHorizontalInsets relation:NSLayoutRelationEqual];
    [self.status autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.subtitle withOffset:kLabelHorizontalInsets relation:NSLayoutRelationEqual];
//    [self.status autoSetDimension:ALDimensionWidth toSize:50];
    
    //image
    [UIView autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.postImage autoSetContentCompressionResistancePriorityForAxis:ALAxisHorizontal];
    }];
    
    [self.postImage autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:kLabelVerticalInsets];
    [self.postImage autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.status withOffset:10 relation:NSLayoutRelationEqual];
    [self.postImage autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:kLabelHorizontalInsets];
    
    [self.postImage autoSetDimension:ALDimensionWidth toSize:44];
    [self.postImage autoSetDimension:ALDimensionHeight toSize:44];
    
    //comment
    [self.comment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitle withOffset:kLabelVerticalInsets relation:NSLayoutRelationEqual];
    
    [UIView autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.comment autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
    }];
    [self.comment autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:kLabelHorizontalInsets];
    [self.comment autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:kLabelHorizontalInsets];
    [self.comment autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:kLabelVerticalInsets relation:NSLayoutRelationGreaterThanOrEqual];
    
    self.didSetupConstraints = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    
    self.comment.preferredMaxLayoutWidth = CGRectGetWidth(self.comment.frame);
}

- (id) setPost:(Post *)post {
    self.title.text = [NSString stringWithFormat:@"%ld", (long)post.num];
    self.subtitle.text = post.subtitle;
    self.comment.text = post.body;
    self.num = post.num;

    self.postImage.tnHeight = post.tnHeight;
    self.postImage.tnWidth = post.tnWidth;
    self.postImage.imageURL = post.thumbnailUrl;
    self.postImage.bigImageUrl = post.imageUrl;
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)updateFonts
{
    self.title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.comment.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

@end
