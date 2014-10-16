//
//  PostCell.m
//  Tabula
//
//  Created by Alexander Tewpin on 25/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "PostCell.h"

@implementation PostCell

- (NSMutableArray *)mediaBox {
    if (!_mediaBox) {
        _mediaBox = [NSMutableArray array];
    }
    return _mediaBox;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib
{
    self.comment.textContainerInset = UIEdgeInsetsMake(CELL_TEXT_VIEW_V_INSET, 0, CELL_TEXT_VIEW_V_INSET, 0);
    self.comment.linkTextAttributes = @{NSForegroundColorAttributeName:[Constants celestiaOrange]};
    self.imagePosition = self.postImage.frame.origin;
    self.textFrame = self.comment.frame;
    
    self.separator = [[UIView alloc]init];
    self.separator.backgroundColor = [Constants celestiaSeparatorGrey];
    [self addSubview:self.separator];
    
    self.moreButton.tintColor = [Constants celestiaDarkGrey];
    self.repliesButton.tintColor = [Constants celestiaDarkGrey];
    self.replyButton.tintColor = [Constants celestiaDarkGrey];
    
    self.status.textColor = [Constants celestiaDarkGrey];
    self.subtitle.textColor = [Constants celestiaDarkGrey];
}

- (id) setPost:(Post *)post {
    //title
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc]init];
    if (![post.name isEqualToString:@""]) {
        title = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@ %@", post.name, post.tripcode]];
        [title addAttribute:NSForegroundColorAttributeName value:[Constants celestiaGreen] range:NSMakeRange(post.name.length+1, post.tripcode.length)];
    } else {
        title = [[NSMutableAttributedString alloc]initWithString:post.tripcode attributes:@{NSForegroundColorAttributeName:[Constants celestiaGreen]}];
    }
    self.title.attributedText = title;
    
    //subtitle
    self.subtitle.text = [NSString stringWithFormat:@"#%@  №%@", post.threadNumber, post.postId];
    
    //date
    self.date.text = post.date;
    
    //image
    if ([post.mediaBox count] == 1) {
        Media *media = post.mediaBox[0];
        
        self.postImage.tnHeight = media.tnHeight;
        self.postImage.tnWidth = media.tnWidth;
        
        self.postImage.frame = CGRectMake(self.imagePosition.x, self.imagePosition.y, 0, 0);
        
        [self.postImage resetSize];
        [self.postImage shiftOnTextInset];
        
        self.postImage.bigImageUrl = media.url;
        [self.postImage setImageWithURL:media.thumbnailUrl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        }];
        
        UIBezierPath *imagePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.postImage.bounds.size.width+CELL_IMAGE_H_INSET, self.postImage.bounds.size.height+CELL_IMAGE_V_INSET)];
        self.comment.textContainer.exclusionPaths = @[imagePath];
        
        self.postImage.hidden = NO;
        self.mediaBoxView.hidden = YES;
    } else if ([post.mediaBox count] > 1 && [post.mediaBox count] <= 4) {
        [self.mediaBoxView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
        
        NSInteger shift = 0;
        NSInteger maxHeight = 0;
        
        for (Media *media in post.mediaBox) {
            TapImageView *image = [[TapImageView alloc]init];
            
            image.tnHeight = media.tnHeight;
            image.tnWidth = media.tnWidth;
            [image resetToMediaSize];
            image.frame = CGRectMake(image.frame.origin.x + shift, image.frame.origin.y, image.frame.size.width, image.frame.size.height);
            shift += image.frame.size.width + CELL_IMAGE_H_INSET;
            if (image.frame.size.height > maxHeight) {
                maxHeight = image.frame.size.height;
            }
            
            image.bigImageUrl = media.url;
            [image setImageWithURL:media.thumbnailUrl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            }];
            
            [self.mediaBoxView addSubview:image];
            [self.mediaBox addObject:image];
        }
        self.mediaBoxView.frame = CGRectMake(self.imagePosition.x, self.imagePosition.y+CELL_TEXT_VIEW_V_INSET, shift-CELL_IMAGE_H_INSET, maxHeight);
        
        //проще, чем двигать текствью
        UIBezierPath *imagePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CELL_TEXT_VIEW_WIDTH, maxHeight+CELL_IMAGE_V_INSET)];
        self.comment.textContainer.exclusionPaths = @[imagePath];
        
        self.mediaBoxView.hidden = NO;
        self.postImage.hidden = YES;
    } else {
        self.comment.textContainer.exclusionPaths = nil;
        self.mediaBoxView.hidden = YES;
        self.postImage.hidden = YES;
    }
    
    //comment (image-depend)
    self.comment.attributedText = post.body;
    
    //replies
    NSInteger postReplies = [post.replies count];
    NSInteger postReplyTo = [post.replyTo count];
    NSString *repliesTitle = @"";
    
    if (postReplies > 0 && postReplyTo > 0) {
        self.repliesButton.hidden = NO;
        repliesTitle = [NSString stringWithFormat:@"▲%ld ▼%ld", (long)postReplyTo, (long)postReplies];
    } else if (postReplies > 0) {
        self.repliesButton.hidden = NO;
        repliesTitle = [NSString stringWithFormat:@"▼%ld", (long)postReplies];
    } else if (postReplyTo > 0) {
        self.repliesButton.hidden = NO;
        repliesTitle = [NSString stringWithFormat:@"▲%ld", (long)postReplyTo];
    } else {
        self.repliesButton.hidden = YES;
    }
    
    //воркэраунд против бага(?) в 7, который несмотря ни на что анимирует изменение текста
    self.repliesButton.titleLabel.text = repliesTitle;
    [self.repliesButton setTitle:repliesTitle forState:UIControlStateNormal];
    
    self.postId = post.postId;
    self.separator.frame = CGRectMake(15, self.frame.size.height-0.5, 305, 0.5);
    
    return self;
}

@end
