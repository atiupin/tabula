//
//  PostCell.h
//  Tabula
//
//  Created by Alexander Tewpin on 25/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "TapImageView.h"
#import "CTTextView.h"

@interface PostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet TapImageView *postImage;
@property (weak, nonatomic) IBOutlet CTTextView *comment;
@property (weak, nonatomic) IBOutlet UIView *mediaBoxView;
@property (strong, nonatomic) UIView *separator;

@property (weak, nonatomic) IBOutlet UIButton *repliesButton;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;

@property (nonatomic) CGPoint imagePosition;
@property (nonatomic) CGRect textFrame;
@property (nonatomic, strong) NSMutableArray *mediaBox; //of TapImageViews

@property (nonatomic, strong) NSString *postId;

- (id) setPost:(Post *)post;

@end
