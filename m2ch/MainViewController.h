//
//  MainViewController.h
//  m2ch
//
//  Created by Александр Тюпин on 08/05/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong)NSFetchedResultsController *fetchedResultsController;

@end
