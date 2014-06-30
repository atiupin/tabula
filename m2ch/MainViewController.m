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

@interface MainViewController ()

@end

@implementation MainViewController

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
    
    NSURL *boardUrl = [NSURL URLWithString:@"http://2ch.hk/makaba/mobile.fcgi?task=get_boards"];
    
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
        NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError];
        self.boardsList = [NSMutableArray array];
        
        //вот здесь-то я и нашел проблему с разбором JSON
//        for (NSDictionary *section in dataDictionary) {
//            NSLog(@"%@", [section class]);
//        }
//        
//        NSLog(@"%@", self.boardsList);
        
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [[self fetchedResultsController] sections];
    if (section < [sections count]) {
        id<NSFetchedResultsSectionInfo> info = [sections objectAtIndex:section];
        return info.numberOfObjects;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"reuseIdentifier";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    BoardData *board = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = board.name;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showBoard"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        BoardData *board = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [segue.destinationViewController setBoardId:board.name];
    }
}
 
@end
