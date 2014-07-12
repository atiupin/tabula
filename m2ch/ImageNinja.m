//
//  ImageNinja.m
//  Tabula
//
//  Created by Alexander Tewpin on 12/07/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "ImageNinja.h"

@implementation ImageNinja

- (id)cachedImages {
    if (!_cachedImages) {
        _cachedImages = [[NSCache alloc]init];
    }
    return _cachedImages;
}

- (void)loadImageForUrl:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error) {
            [self decodeDataAndPutIntoCache:location withLinkRef:[url absoluteString]];
        } else {
            [self returnError];
        }
    }];
    [task resume];
}

- (void)decodeDataAndPutIntoCache:(NSURL *)location withLinkRef:(NSString *)linkRef {
    NSData *data = [NSData dataWithContentsOfURL:location];
    UIImage *image = [UIImage imageWithData:data];
    [self.cachedImages setObject:image forKey:linkRef];
}

- (void)returnError {
    
}

@end
