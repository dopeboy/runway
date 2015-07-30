//
//  FacebookAlbum.h
//  FacebookTest
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FacebookAlbum : NSObject

+ (void)getAlbumsWithCompletionBlock:(void (^)(NSArray *albums))completion;

+ (void)getPhotosInAlbum:(FacebookAlbum *)album
     withCompletionBlock:(void (^)(NSArray *photos))completion;

@property (nonatomic, strong) NSString *albumId;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) NSString *albumDescription;
@property (nonatomic, strong) NSString *albumCoverPhotoId;
@property (nonatomic) int albumImageCount;
@property (nonatomic, strong) UIImage *albumCoverCache;

- (FacebookAlbum *)initWithData:(NSDictionary *)data;
- (void)getAlbumCoverPhotoWithCompletionBlock:(void (^)())completion;

@end
