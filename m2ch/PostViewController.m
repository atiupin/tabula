//
//  PostViewController.m
//  Tabula
//
//  Created by Alexander Tewpin on 02/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "PostViewController.h"
#import "JTSImageViewController.h"
#import "JTSImageInfo.h"
#import "Declension.h"

@interface PostViewController ()

@property (nonatomic) NSInteger topCommentRow;
@property (nonatomic) NSInteger bottomCommentRow;
@property (nonatomic) NSInteger mainPostRow;
@property (nonatomic) NSInteger mainPostShift;
@property (nonatomic) NSInteger repliesShift;
@property (nonatomic) NSInteger postCount;

@property (nonatomic) NSInteger clearSeparator1;
@property (nonatomic) NSInteger clearSeparator2;

@end

@implementation PostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[PostTableViewCell class] forCellReuseIdentifier:@"reuseIndenifier"];
    [self.tableView registerClass:[CommentTableViewCell class] forCellReuseIdentifier:@"commentCell"];
    
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIContentSizeCategoryDidChangeNotification
     object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         [self.tableView reloadData];
     }];
    
    self.currentThread = [Thread currentThreadWithThread:self.thread andReplyTo:self.replyTo andReplies:self.replies andPostId:self.postId];
    
    self.topCommentRow = -1;
    self.bottomCommentRow = -1;
    self.mainPostRow = 0;
    self.mainPostShift = 0;
    self.repliesShift = 0;
    self.postCount = self.currentThread.posts.count;
    
    self.clearSeparator1 = -1;
    self.clearSeparator2 = -1;
    
    CGFloat contentHeight = 64;
    
    if (self.replyTo.count > 0) {
        self.topCommentRow = self.replyTo.count;
        self.mainPostRow = self.replyTo.count + 1;
        self.mainPostShift = 1;
        self.repliesShift += 1;
        self.postCount += 1;
        self.clearSeparator1 = self.replyTo.count - 1;
        contentHeight += 20;
    }
    if (self.replies.count > 0) {
        self.bottomCommentRow = self.mainPostRow + 1;
        self.repliesShift += 1;
        self.postCount += 1;
        self.clearSeparator2 = self.mainPostRow;
        contentHeight += 20;
    }
    
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCell"];
        Declension *declension = [[Declension alloc]init];
        cell.comment.text = [declension replyTo:self.replyTo.count];
        return cell;
    } else if (indexPath.row == self.bottomCommentRow) {
        PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCell"];
        Declension *declension = [[Declension alloc]init];
        cell.comment.text = [declension replies:self.replies.count];
        return cell;
    } else {
        PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIndenifier"];
        Post *post = [[Post alloc]init];
        if (indexPath.row < self.mainPostRow) {
            post = self.currentThread.posts[indexPath.row];
        } else if (indexPath.row == self.mainPostRow) {
            post = self.currentThread.posts[indexPath.row - self.mainPostShift];
        } else {
            post = self.currentThread.posts[indexPath.row - self.repliesShift];
        }
        
        if (indexPath.row == self.clearSeparator1 || indexPath.row == self.clearSeparator2) {
            cell.separatorInset = UIEdgeInsetsMake(0, 9999, 0, 0);
        }
        
        [cell updateFonts];
        [cell setPost:post];
        
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        cell.comment.delegate = self;
        
        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapped:)];
        [cell.comment setTag:cell.num];
        tgr.delegate = self;
        [cell.postImage addGestureRecognizer:tgr];
        
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)imageTapped:(UITapGestureRecognizer *)sender {
    
    TapImageView *image = (TapImageView *)sender.view;
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    
    NSLog(@"%@", image.bigImageUrl);
    imageInfo.imageURL = image.bigImageUrl;
    imageInfo.referenceRect = image.frame;
    imageInfo.referenceView = image.superview;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundStyle_ScaledDimmed];
    
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOffscreen];
}

- (CGFloat)heightForPost:(Post *)post {
    
    if (self == self.navigationController.topViewController) {
        
        if (post.postHeight) {
            return post.postHeight;
        } else {
            
            PostTableViewCell *cell = [[PostTableViewCell alloc]init];
            
            [cell setTextPost:post];
            
            [cell setNeedsUpdateConstraints];
            [cell updateConstraintsIfNeeded];
            
            cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(cell.bounds));
            
            [cell setNeedsLayout];
            [cell layoutIfNeeded];
            
            CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            
            height += 1;
            post.postHeight = height;
            
            return height;
        }
    }
    
    return 0;
}

@end
