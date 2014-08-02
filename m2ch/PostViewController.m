//
//  PostViewController.m
//  Tabula
//
//  Created by Alexander Tewpin on 02/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "PostViewController.h"

@interface PostViewController ()

@property (nonatomic) NSInteger topCommentRow;
@property (nonatomic) NSInteger mainPostRow;
@property (nonatomic) NSInteger bottomCommentRow;
@property (nonatomic) NSInteger mainPostShift;
@property (nonatomic) NSInteger repliesShift;
@property (nonatomic) NSInteger postCount;

@property (nonatomic, strong) NSMutableArray *clearSeparatorsIndexes;

@property (nonatomic) CGFloat mainRowContentOffset;
@property (nonatomic) BOOL needFlash;

@end

@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Пост";
    [self.tableView registerClass:[CommentTableViewCell class] forCellReuseIdentifier:@"commentCell"];
    
    self.currentThread = [Thread currentThreadWithThread:self.thread andReplyTo:self.replyTo andReplies:self.replies andPostId:self.postId];
    
    self.needFlash = NO;
    
    self.topCommentRow = -1;
    self.bottomCommentRow = -1;
    self.mainPostRow = 0;
    self.mainPostShift = 0;
    self.repliesShift = 0;
    self.postCount = self.currentThread.posts.count;
    
    self.clearSeparatorsIndexes = [@[] mutableCopy];
    
    CGFloat contentHeight = 64;
    
    if (self.replyTo.count > 0) {
        self.topCommentRow = self.replyTo.count;
        self.mainPostRow = self.replyTo.count + 1;
        self.mainPostShift = 1;
        self.repliesShift += 1;
        self.postCount += 1;
        [self.clearSeparatorsIndexes addObject:[NSNumber numberWithLong:self.replyTo.count-1]];
        contentHeight += 20;
    }
    if (self.replies.count > 0) {
        self.bottomCommentRow = self.mainPostRow + 1;
        self.repliesShift += 1;
        self.postCount += 1;
        [self.clearSeparatorsIndexes addObject:[NSNumber numberWithLong:self.bottomCommentRow]];
        contentHeight += 20;
    }
    
    NSInteger lastRow = [self.currentThread.posts count]+self.repliesShift-1;
    [self.clearSeparatorsIndexes addObject:[NSNumber numberWithLong:self.mainPostRow]];
    [self.clearSeparatorsIndexes addObject:[NSNumber numberWithLong:lastRow]];
    
    NSInteger i = self.replyTo.count;
    CGPoint contentOffset = CGPointMake(0, 0);
    
    for (int k = 0; k < i; k++) {
        contentOffset.y += [self heightForPost:[self.currentThread.posts objectAtIndex:k]];
    }
    
    contentHeight += contentOffset.y;
    
    for (NSInteger k = i; k < self.currentThread.posts.count; k++) {
        contentHeight += [self heightForPost:[self.currentThread.posts objectAtIndex:k]];
    }

    CGFloat footer = self.tableView.frame.size.height - contentHeight + contentOffset.y;
    if (footer < 0) {
        footer = 0;
    }
    
    //убирает сепараторы снизу и при загрузке
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, footer)];
    UIView *endline = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0.5)];
    endline.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
    [self.tableView.tableFooterView addSubview:endline];
    
    [self.tableView setContentOffset:contentOffset];
    self.mainRowContentOffset = contentOffset.y - self.navigationController.navigationBar.frame.size.height;
    
    UITapGestureRecognizer *tgrCell = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearTextViewSelections)];
    tgrCell.delegate = self;
    [self.tableView.tableFooterView addGestureRecognizer:tgrCell];
    
    [self creationEnded];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.postCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.topCommentRow) {
        CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCell"];
        cell.comment.text = [Declension replyTo:self.replyTo.count];
        
        UITapGestureRecognizer *tgrCell = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearTextViewSelections)];
        tgrCell.delegate = self;
        [cell addGestureRecognizer:tgrCell];
        
        return cell;
    } else if (indexPath.row == self.bottomCommentRow) {
        CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCell"];
        cell.comment.text = [Declension replies:self.replies.count];
        
        UITapGestureRecognizer *tgrCell = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearTextViewSelections)];
        tgrCell.delegate = self;
        [cell addGestureRecognizer:tgrCell];
        
        return cell;
    } else {
        PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
        Post *post = [[Post alloc]init];
        if (indexPath.row < self.mainPostRow) {
            post = self.currentThread.posts[indexPath.row];
        } else if (indexPath.row == self.mainPostRow) {
            post = self.currentThread.posts[indexPath.row - self.mainPostShift];
        } else {
            post = self.currentThread.posts[indexPath.row - self.repliesShift];
        }
        
        if ([self.clearSeparatorsIndexes containsObject:[NSNumber numberWithLong:indexPath.row]]) {
            cell.separatorInset = UIEdgeInsetsMake(0, 9999, 0, 0);
        } else {
            //дефолтное значение, константы похоже не существует
            cell.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
        }
        
        cell.separator.hidden = YES;
        
        [cell setPost:post];
        
        if (indexPath.row == self.mainPostRow) {
            cell.repliesButton.hidden = YES;
        } else {
            cell.repliesButton.hidden = NO;
        }
        
        cell.comment.delegate = self;
        
        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapped:)];
        tgr.delegate = self;
        [cell.postImage addGestureRecognizer:tgr];
        
        UITapGestureRecognizer *tgrCell = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearTextViewSelections)];
        tgrCell.delegate = self;
        [cell addGestureRecognizer:tgrCell];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.topCommentRow) {
        return 20;
    } else if (indexPath.row == self.bottomCommentRow) {
        return 20;
    } else {
        Post *post = [[Post alloc]init];
        if (indexPath.row < self.mainPostRow) {
            post = self.currentThread.posts[indexPath.row];
        } else if (indexPath.row == self.mainPostRow) {
            post = self.currentThread.posts[indexPath.row - self.mainPostShift];
        } else {
            post = self.currentThread.posts[indexPath.row - self.repliesShift];
        }
        return [self heightForPost:post];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!(indexPath.row == self.topCommentRow || indexPath.row == self.bottomCommentRow || indexPath.row == self.mainPostRow)) {
        NSInteger shift = 0;
        if (indexPath.row > self.mainPostRow) {
            if (self.replyTo.count > 0) {
                shift += 1;
            }
            if (self.replies.count > 0) {
                shift += 1;
            }
        } else if (indexPath.row < self.mainPostRow) {
            shift = 0;
        }
        
        NSInteger postNum = indexPath.row;
        postNum -= shift;
        NSUInteger indexArray[] = {0, postNum};
        NSIndexPath *newIndexPath = [NSIndexPath indexPathWithIndexes:indexArray length:2];
        
        UrlNinja *un = [[UrlNinja alloc]init];
        un.boardId = self.boardId;
        un.threadId = self.threadId;
        un.postId = self.currentThread.linksReference[newIndexPath.row];
        [self openPostWithUrlNinja:un];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)openPostWithUrlNinja:(UrlNinja *)urlNinja {
    if ([self.threadId isEqualToString:urlNinja.threadId] && [self.boardId isEqualToString:urlNinja.boardId] && [self.postId isEqualToString:urlNinja.postId]) {
        
        self.needFlash = YES;
        NSUInteger scrollIndex = self.mainPostRow;
        
        if (self.replyTo.count > 0) {
            scrollIndex -= 1;
        }
        
        NSUInteger scrollIndexArray[] = {0, scrollIndex};
        NSIndexPath *scrollIndexPath = [NSIndexPath indexPathWithIndexes:scrollIndexArray length:2];
        [self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
        if (self.tableView.contentOffset.y == (self.mainRowContentOffset)) {
            [self makeFlash];
        }
        
    } else {
        [super openPostWithUrlNinja:urlNinja];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self makeFlash];
}

- (void)makeFlash {
        NSUInteger mainIndexArray[] = {0, self.mainPostRow};
        NSIndexPath *mainIndexPath = [NSIndexPath indexPathWithIndexes:mainIndexArray length:2];
        PostCell *cell = (PostCell *)[self.tableView cellForRowAtIndexPath:mainIndexPath];
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            cell.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                cell.backgroundColor = [UIColor whiteColor];
            } completion:^(BOOL finished) {
                
            }];
        }];
}

- (IBAction)showRepliesButton:(id)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    Post *post = [[Post alloc]init];
    
    UrlNinja *un = [[UrlNinja alloc]init];
    un.boardId = self.boardId;
    un.threadId = self.threadId;
    
    if (indexPath.row < self.mainPostRow) {
        post = self.currentThread.posts[indexPath.row];
        if (post.replyTo.count == 0 && post.replies.count == 1 && [post.replies[0] isEqualToString:self.postId]) {
            un.postId = self.postId;
        } else {
            un.postId = post.postId;
        }
    } else if (indexPath.row == self.mainPostRow) {
        un.postId = self.postId;
    } else {
        post = self.currentThread.posts[indexPath.row - self.repliesShift];
        if (post.replies.count == 0 && post.replyTo.count == 1 && [post.replyTo[0] isEqualToString:self.postId]) {
            un.postId = self.postId;
        } else {
            un.postId = post.postId;
        }
    }
    
    [self openPostWithUrlNinja:un];
}

@end
