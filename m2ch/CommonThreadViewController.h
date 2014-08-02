//
//  CommonThreadViewController.h
//  Tabula
//
//  Created by Alexander Tewpin on 31/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "CommonViewController.h"

@interface CommonThreadViewController : CommonViewController <NewPostControllerDelegate>

@property (nonatomic, strong) NSString *reply;
@property (nonatomic, strong) NSString *quote;
@property (nonatomic, strong) UITextView *responder;

- (void)loadMorePosts;

- (CGFloat)heightForPost:(Post *)post;
- (void)cacheHeightForAllPosts;

- (void)clearTextViewSelections;
- (void)restoreButtonTextInCell:(PostCell *)cell;

- (void)replyOrQuoteWithCell:(PostCell *)cell;
- (void)showRepliesWithCell:(PostCell *)cell;

@end
