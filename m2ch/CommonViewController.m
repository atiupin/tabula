//
//  CommonViewController.m
//  Tabula
//
//  Created by Alexander Tewpin on 03/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "CommonViewController.h"

#import "BoardViewController.h"
#import "ThreadViewController.h"
#import "PostViewController.h"

@interface CommonViewController ()

@end

@implementation CommonViewController

#pragma mark - Links and Segues

- (void)attributedLabel:(__unused TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    UrlNinja *urlNinja = [UrlNinja unWithUrl:url];
    
    switch (urlNinja.type) {
        case boardLink: {
            //открыть борду
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            BoardViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"BoardTag"];
            controller.boardId = urlNinja.boardId;
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case boardThreadLink: {
            //открыть тред
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            ThreadViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTag"];
            controller.boardId = urlNinja.boardId;
            controller.threadId = urlNinja.threadId;
            
            //без этого фачится размер заголовка
            controller.navigationItem.title = [NSString stringWithFormat:@"Тред в /%@/", urlNinja.boardId];
            
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case boardThreadPostLink: {
            [self openPostWithUN:urlNinja];
        }
            break;
        default:
            //внешня ссылка - предложение открыть в сафари
            [[[UIActionSheet alloc] initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:NSLocalizedString(@"Отмена", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Открыть ссылку в Safari", nil), nil] showInView:self.view];
            break;
    }
}

//это порефакторить бы
- (void)openPostWithUN:(UrlNinja *)urlNinja {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    if ([self.threadId isEqualToString:urlNinja.threadId] && [self.boardId isEqualToString:urlNinja.boardId] && [self.postId isEqualToString:urlNinja.postId]) {
        NSUInteger postNum = [self.currentThread.linksReference indexOfObject:urlNinja.postId];
        NSUInteger indexArray[] = {0, postNum};
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexArray length:2];

        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        return;
    }
    if ([self.threadId isEqualToString:urlNinja.threadId] && [self.boardId isEqualToString:urlNinja.boardId]) {
        
        NSUInteger postNum = [self.thread.linksReference indexOfObject:urlNinja.postId];
        if (postNum != NSNotFound) {
            NSUInteger indexArray[] = {0, postNum};
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexArray length:2];
            Post *post = self.thread.posts[indexPath.row];
            PostViewController *destination = [storyboard instantiateViewControllerWithIdentifier:@"PostTag"];
            
            [destination setThread:self.thread];
            [destination setBoardId:self.boardId];
            [destination setThreadId:self.threadId];
            [destination setPostId:post.postId];
            [destination setReplyTo:post.replyTo];
            [destination setReplies:post.replies];
            
            [self.navigationController pushViewController:destination animated:YES];
            
            return;
        }
    }
    ThreadViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTag"];
    controller.boardId = urlNinja.boardId;
    controller.threadId = urlNinja.threadId;
    controller.postId = urlNinja.postId;
    [self.navigationController pushViewController:controller animated:YES];
    
    return;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"newPost"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        GetRequestViewController *destinationController = (GetRequestViewController *)navigationController.topViewController;
        [destinationController setBoardId:self.boardId];
        [destinationController setThreadId:self.threadId];
        [destinationController setDraft:self.thread.postDraft];
        destinationController.postView.text = self.thread.postDraft;
        destinationController.delegate = self;
    }
    
    if ([segue.identifier isEqualToString:@"showPost"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *post = self.currentThread.posts[indexPath.row];
        PostViewController *destination = segue.destinationViewController;
        [destination setThread:self.thread];
        [destination setBoardId:self.boardId];
        [destination setThreadId:self.threadId];
        [destination setPostId:post.postId];
        [destination setReplyTo:post.replyTo];
        [destination setReplies:post.replies];
    }
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
}

#pragma mark - Gesture Recognizers

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

#pragma mark - New Post Delegate

- (void)postCanceled:(NSString *)draft{
    self.thread.postDraft = draft;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postPosted {
    self.thread.postDraft = nil;
    [self loadUpdatedData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Post Height

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

#pragma mark - Little Helpers

- (void)loadUpdatedData {
    
}

@end
