//
//  DebugController.m
//  m2ch
//
//  Created by Александр Тюпин on 29/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "DebugController.h"
#import "UrlNinja.h"

@implementation DebugController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *source = @"/au/";
    self.source.text = source;
    NSURL *url = [NSURL URLWithString:source];
    UrlNinja *un = [UrlNinja unWithUrl:url];
    
    switch (un.type) {
        case boardLink:
            self.type.text = @"B Link";
            break;
        case boardThreadLink:
            self.type.text = @"BT Link";
            break;
        case boardThreadPostLink:
            self.type.text = @"BTP Link";
            break;
        default:
            self.type.text = @"External Link";
            break;
    }
    
    self.board.text = un.boardId;
    self.thread.text = un.threadId;
    self.post.text = un.postId;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
