//
//  ThreadPosition.h
//  Tabula
//
//  Created by Alexander Tewpin on 27/06/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ThreadData : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *position;
@property (nonatomic, retain) NSNumber *count;

@end
