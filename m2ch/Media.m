//
//  Media.m
//  Tabula
//
//  Created by Alexander Tewpin on 06/08/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import "Media.h"

@implementation Media

- (id)initWithDictionary:(NSDictionary *)source andRootUrl:(NSURL *)url {
    
    NSString *thumbnail = [source objectForKey:@"thumbnail"];
    NSString *image = [source objectForKey:@"image"];
    NSString *path = [source objectForKey:@"path"];
    
    if (thumbnail != (id)[NSNull null] && thumbnail != nil) {
        self.thumbnailUrl = [NSURL URLWithString:thumbnail relativeToURL:url];
    }
    
    //вакаба
    if (image != (id)[NSNull null] && image != nil) {
        self.url = [NSURL URLWithString:image relativeToURL:url];
    }
    
    //макаба
    if (path != (id)[NSNull null] && path != nil) {
        self.url = [NSURL URLWithString:path relativeToURL:url];
    }
    
    NSNumber *tnWidth = [source objectForKey:@"tn_width"];
    
    if (tnWidth != (id)[NSNull null]) {
        self.tnWidth = [tnWidth intValue];
    }
    else {
        self.tnWidth = 0;
    }
    
    NSNumber *tnHeight = [source objectForKey:@"tn_height"];
    
    if (tnHeight != (id)[NSNull null]) {
        self.tnHeight = [tnHeight intValue];
    }
    else {
        self.tnHeight = 0;
    }
    
    NSNumber *imgWidth = [source objectForKey:@"width"];
    
    if (imgWidth != (id)[NSNull null]) {
        self.imgWidth = [imgWidth intValue];
    }
    else {
        self.imgWidth = 0;
    }
    
    NSNumber *imgHeight = [source objectForKey:@"height"];
    
    if (imgHeight != (id)[NSNull null]) {
        self.imgHeight = [imgHeight intValue];
    }
    else {
        self.imgHeight = 0;
    }

    return self;
}

+ (id)mediaWithDictionary:(NSDictionary *)source andRootUrl:(NSURL *)url {
    return [[self alloc] initWithDictionary:source andRootUrl:url];
}

@end
