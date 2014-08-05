//
//  MainViewController.m
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "MainViewController.h"
#import "BoardViewController.h"
#import "BoardData.h"
#import "ThreadViewController.h"
#import "UrlNinja.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (NSMutableArray *)sectionList {
    if (!_sectionList) {
        _sectionList = [NSMutableArray array];
    }
    return _sectionList;
}

- (NSMutableArray *)sectionNames {
    if (!_sectionNames) {
        _sectionNames = [NSMutableArray array];
    }
    return _sectionNames;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIContentSizeCategoryDidChangeNotification
     object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         [self.tableView reloadData];
     }];
    [self loadData];
}

- (NSFetchedResultsController *) fetchedResultsController {
    if (_fetchedResultsController == nil) {
        _fetchedResultsController =
        [BoardData MR_fetchAllSortedBy:@"name"
                         ascending:YES withPredicate:nil groupBy:nil delegate:self];
        
        NSInteger count = [[[_fetchedResultsController sections]
                            valueForKeyPath:@"@sum.numberOfObjects"] integerValue];
        if (count == 0) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                NSArray *boardsList =
                [NSArray arrayWithObjects:@"de", @"c", @"b", @"mlp", @"mobi", @"media", @"wrk", @"t", nil];
                for (NSString *board in boardsList) {
                    BoardData *next = [BoardData MR_createInContext:localContext];
                    next.name = board;
                }

            }];
        }
    }
    return _fetchedResultsController;
}

-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // TODO: insert NSFetchedResultsControllerDelegate boilerplate 
    [self.tableView reloadData];
}

- (void)loadData {
    
    NSURL *boardUrl = [NSURL URLWithString:@"https://2ch.hk/makaba/mobile.fcgi?task=get_boards"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:boardUrl];
    [task resume];
    
}

#pragma mark - Data loading and creating

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    NSData *data = [NSData dataWithContentsOfURL:location];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        NSError *dataError = nil;
        NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&dataError];

        NSArray *sectionsArray = [dataDictionary allKeys];
        
        for (NSString *key in sectionsArray) {
            NSMutableArray *sectionArray = [NSMutableArray array];
            for (NSDictionary *section in [dataDictionary objectForKey:key]) {
                Board *board = [[Board alloc]init];
                board.boardSection = key;
                board.boardId = [section objectForKey:@"id"];
                board.boardName = [section objectForKey:@"name"];
                [sectionArray addObject:board];
            }
            [self.sectionList addObject:sectionArray];
            [self.sectionNames addObject:key];
        }
        
        NSArray *sortingArray = @[@"Тематика", @"Творчество", @"Техника и софт", @"Игры", @"Японская культура", @"Разное", @"Взрослым", @"Пробное"];
        
        for (NSString *iStr in sortingArray) {
            NSInteger i = [self.sectionNames indexOfObject:iStr];
            [self.sectionList addObject:self.sectionList[i]];
            [self.sectionNames addObject:self.sectionNames[i]];
            [self.sectionList removeObjectAtIndex:i];
            [self.sectionNames removeObjectAtIndex:i];
        }
        
        for (NSMutableArray *array in self.sectionList) {
            [array sortUsingDescriptors:
             [NSArray arrayWithObjects:
              [NSSortDescriptor sortDescriptorWithKey:@"boardId" ascending:YES], nil]];
        }

        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        });
    });
}

#pragma mark - Session stuff

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView

{
    return self.sectionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    NSArray *sections = [[self fetchedResultsController] sections];
//    if (section < [sections count]) {
//        id<NSFetchedResultsSectionInfo> info = [sections objectAtIndex:section];
//        return info.numberOfObjects;
//    }
    NSArray *sectionArray = self.sectionList[section];
    return sectionArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionNames[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"reuseIdentifier";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    NSArray *sectionArray = self.sectionList[indexPath.section];
    Board *board = sectionArray[indexPath.row];
//    BoardData *board = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = board.boardId;
    cell.detailTextLabel.text = board.boardName;
//    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showBoard"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSArray *sectionArray = self.sectionList[indexPath.section];
        Board *board = sectionArray[indexPath.row];
//        BoardData *board = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [segue.destinationViewController setBoardId:board.boardId];
    }
}

//debug only
- (IBAction)showTabulaThread:(id)sender {
    UrlNinja *urlNinja = [[UrlNinja alloc]init];
    urlNinja.boardId = @"mobi";
    urlNinja.threadId = @"300665";
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ThreadViewController *destination = [storyboard instantiateViewControllerWithIdentifier:@"ThreadTag"];
    [destination setBoardId:urlNinja.boardId];
    [destination setThreadId:urlNinja.threadId];
    [destination setPostId:urlNinja.postId];
    
    [self.navigationController pushViewController:destination animated:YES];
}

@end
