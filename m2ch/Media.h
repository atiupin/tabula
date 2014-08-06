//
//  Media.h
//  Tabula
//
//  Created by Alexander Tewpin on 06/08/14.
//  Copyright (c) 2014 Alexander Tewpin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Media : NSObject

typedef NS_ENUM(NSUInteger, mediaType) {
    image = 0,
    webm = 1,
};

@property (nonatomic, assign) enum mediaType type;

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *thumbnailUrl;

@property (nonatomic) NSInteger tnHeight;
@property (nonatomic) NSInteger tnWidth;
@property (nonatomic) NSInteger imgHeight;
@property (nonatomic) NSInteger imgWidth;

- (id)initWithDictionary:(NSDictionary *)source andRootUrl:(NSURL *)url;
+ (id)mediaWithDictionary:(NSDictionary *)source andRootUrl:(NSURL *)url;

@end
