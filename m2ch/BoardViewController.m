//
//  BoardViewController.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "BoardViewController.h"

@interface BoardViewController ()

@end

@implementation BoardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = [NSString stringWithFormat:@"/%@/", self.boardId];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    //убирает сепараторы снизу и при загрузке
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.tableView registerClass:[ThreadTableViewCell class] forCellReuseIdentifier:@"reuseIndenifier"];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    
    NSString *stringUrl = [NSString stringWithFormat:@"%@/%@/wakaba.json", ROOT_URL, self.boardId];
    self.mainUrl = [NSURL URLWithString:stringUrl];
    [self loadDataForUrl:self.mainUrl isMainUrl:YES handleError:YES];
}

#pragma mark - Data loading and creating

- (void)createDataWithLocation:(NSURL *)location {
    [super createDataWithLocation:location];
    NSData *data = [NSData dataWithContentsOfURL:location];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        [self loadThreadsListWithData:data];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self performSelectorOnMainThread:@selector(creationEnded) withObject:nil waitUntilDone:NO];
        });
    });
}

- (void)loadThreadsListWithData:(NSData *)data {
    
    NSError *dataError = nil;
    NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];
    self.threadsList = [NSMutableArray array];
    
    NSArray *threadsArray = [dataDictionary objectForKey:@"threads"];
    
    for (NSDictionary *i in threadsArray) {
        Thread *thread = [[Thread alloc]init];
        thread.posts = [NSMutableArray array];
        NSDictionary *postDictionary = [[[i objectForKey:@"posts"] objectAtIndex:0] objectAtIndex:0];
        Post *post = [Post postWithDictionary:postDictionary andBoardId:self.boardId andThreadId:nil];
        post.boardId = self.boardId;
        post.threadId = post.postId;
        post.replyCount = [[i objectForKey:@"reply_count"] intValue];
        post.replyCount += 1; //меняем ответы на посты
        
        post.newReplies = 0;
        NSString *comboId = [NSString stringWithFormat:@"%@%ld", self.boardId, (long)post.num];
        
        //на всякий случай, если в результате глюков или легаси ДБ по запросу будет более одного результата, то ищем наибольший
        NSArray *dataArray = [ThreadData MR_findByAttribute:@"name" withValue:comboId];
        if (dataArray.count != 0) {
            int oldCount = 0;
            for (ThreadData *thread in dataArray) {
                if (oldCount <= [thread.count intValue]) {
                    oldCount = [thread.count intValue];
                }
            }
            post.newReplies = post.replyCount - oldCount;
        } else {
            //если в БД записи не найдены, то все посты считаются новыми
            post.newReplies = post.replyCount;
            post.replyCount = 0;
        }
        
        Declension *declension = [Declension stringWithAnswerCount:post.replyCount andNewPosts:post.newReplies];
        post.threadReplies = declension.output;
        
        [self.threadsList addObject:post];
    }
}

- (void)refresh {
    [self loadDataForUrl:self.mainUrl isMainUrl:YES handleError:NO];
}

#pragma mark - Data updating

- (void)creationEnded {
    [super creationEnded];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.threadsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIndenifier"];
    
    [cell updateFonts];
    
    Post *post = self.threadsList[indexPath.row];
    
    [cell setPost:post];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    cell.comment.delegate = self;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapped:)];
    tgr.delegate = self;
    [cell.postImage addGestureRecognizer:tgr];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ThreadTableViewCell *cell = [[ThreadTableViewCell alloc]init];
    
    Post *post = self.threadsList[indexPath.row];
    
    [cell setPost:post];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    height += 1;
    
    return height;
    
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThreadTableViewCell *cell = (ThreadTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    Post *post = self.threadsList[indexPath.row];
    
    if (post.replyCount == 0) {
        post.replyCount = post.newReplies;
    }
    
    Declension *declension = [Declension stringWithAnswerCount:post.replyCount andNewPosts:0];
    post.threadReplies = declension.output;
    
    [cell setPost:post];
    
    UrlNinja *urlNinja = [[UrlNinja alloc]init];
    urlNinja.boardId = self.boardId;
    urlNinja.threadId = post.threadId;
    [self openThreadWithUrlNinja:urlNinja];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end