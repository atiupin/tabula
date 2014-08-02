//
//  CommonThreadViewController.m
//  Tabula
//
//  Created by Alexander Tewpin on 31/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "CommonThreadViewController.h"

@interface CommonThreadViewController ()

@end

@implementation CommonThreadViewController

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self clearTextViewSelections];
}

- (void)loadMorePosts {
    
}

//изжить!
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"newPost"]) {
        [self clearTextViewSelections];
        UINavigationController *navigationController = segue.destinationViewController;
        GetRequestViewController *destinationController = (GetRequestViewController *)navigationController.topViewController;
        [destinationController setBoardId:self.boardId];
        [destinationController setThreadId:self.threadId];
        [destinationController setDraft:self.thread.postDraft];
        destinationController.postView.text = self.thread.postDraft;
        destinationController.delegate = self;
    }
}

#pragma mark - New Post Delegate

- (void)postCanceled:(NSString *)draft{
    self.thread.postDraft = draft;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postPosted {
    self.thread.postDraft = nil;
    [self loadMorePosts];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Post Height

- (CGFloat)heightForPost:(Post *)post {
    //особого выигрыша в скорости хранение сторейджа не дает, но пусть будет. От boundingRectWithSize отказался, потому что выигрыша в скорости тоже нет, нефиг усложнять код
    if (!post.postHeight) {[self.dummyStorage setAttributedString:post.body];
        NSLayoutManager *layoutManager = self.dummyStorage.layoutManagers[0];
        NSTextContainer *textContainer = layoutManager.textContainers[0];
        
        CGFloat tnHeight = post.tnHeight;
        CGFloat tnWidth = post.tnWidth;
        
        if (tnHeight > 0 && tnWidth > 0) {
            CGFloat i = 1;
            
            if (tnHeight > CELL_IMAGE_BOX_SIZE_PX || tnWidth > CELL_IMAGE_BOX_SIZE_PX) {
                if (tnHeight > tnWidth) {
                    i = CELL_IMAGE_BOX_SIZE_PX/tnHeight;
                } else {
                    i = CELL_IMAGE_BOX_SIZE_PX/tnWidth;
                }
                tnHeight = tnHeight*i;
                tnWidth = tnWidth*i;
            }
            
            UIBezierPath *imagePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, (tnWidth/2)+CELL_IMAGE_H_INSET, (tnHeight/2)+CELL_IMAGE_V_INSET)];
            textContainer.exclusionPaths = @[imagePath];
        } else {
            textContainer.exclusionPaths = nil;
        }
        
        [layoutManager glyphRangeForTextContainer:textContainer];
        CGSize size = [layoutManager usedRectForTextContainer:textContainer].size;
        if (size.height < (tnHeight/2)) {
            size.height = (tnHeight/2);
        }
        post.postHeight = size.height+CELL_H_MINUS_TEXT+CELL_TEXT_VIEW_V_INSET*2+1;
    }
    return post.postHeight;
}

- (void) cacheHeightForAllPosts {
    for (Post *post in self.thread.posts) {
        [self heightForPost:post];
    }
}

#pragma mark - Reply and Quote 
- (NSString *)makeQuote:(NSString *)sourceString {
    NSMutableString *mString = [sourceString mutableCopy];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSRegularExpression *quoteReg = [NSRegularExpression regularExpressionWithPattern:@"^.+$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [quoteReg enumerateMatchesInString:sourceString options:0 range:NSMakeRange(0, sourceString.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [resultArray addObject:result];
    }];
    NSInteger shift = 0;
    for (NSTextCheckingResult *result in resultArray) {
        [mString insertString:@">" atIndex:result.range.location + shift];
        shift ++;
    }
    return mString;
}

#pragma mark - Buttons handling

- (void)replyOrQuoteWithCell:(PostCell *)cell {
    NSString *reply = [NSString stringWithFormat:@">>%@", cell.postId];
    NSString *quote = [cell.comment.text substringWithRange:cell.comment.selectedRange];
    if (cell.comment.selectedRange.length == 0) { // ответить
        if (![self.thread.postDraft isEqualToString:@""] && self.thread.postDraft) {
            self.thread.postDraft = [NSString stringWithFormat:@"%@%@\n", self.thread.postDraft, reply];
        } else {
            self.thread.postDraft = [NSString stringWithFormat:@"%@\n", reply];
        }
    } else { //ответ с цитатой
        if (![self.thread.postDraft isEqualToString:@""] && self.thread.postDraft) {
            self.thread.postDraft = [NSString stringWithFormat:@"%@\n%@\n%@\n", self.thread.postDraft, reply, quote];
        } else {
            self.thread.postDraft = [NSString stringWithFormat:@"%@\n%@\n", reply, quote];
        }
    }
    
    [self performSegueWithIdentifier:@"newPost" sender:self];
}

- (void)showRepliesWithCell:(PostCell *)cell {
    UrlNinja *un = [[UrlNinja alloc]init];
    un.boardId = self.boardId;
    un.threadId = self.threadId;
    un.postId = cell.postId;
    [self openPostWithUrlNinja:un];
}

#pragma mark - Other common methods

- (void) clearTextViewSelections {
    NSArray *cellsArray = [self.tableView visibleCells];
    for (PostCell *cell in cellsArray) {
        if ([cell.comment isKindOfClass:[UITextView class]]) {
            cell.comment.selectedRange = NSMakeRange(0, 0);
        }
    }
}

- (void) restoreButtonTextInCell:(PostCell *)cell {
    cell.comment.selectedRange = NSMakeRange(0, 0);
    [cell.replyButton setTitle:@"Ответить" forState:UIControlStateNormal];
}

@end
