//
//  ImageNinja.h
//  Tabula
//
//  Created by Alexander Tewpin on 12/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageNinja : NSObject

@property (nonatomic, strong) NSCache *cachedImages;

- (void)loadImageForUrl:(NSURL *)url;

@end