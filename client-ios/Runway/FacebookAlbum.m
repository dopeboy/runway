//
//  FacebookAlbum.m
//  FacebookTest
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "FacebookAlbum.h"
#import "FacebookPhoto.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#define WIDTH_GOAL         100

@implementation FacebookAlbum

////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
#pragma mark - Getters/Setters
- (NSString *)albumDescription
{
    return _albumDescription ? _albumDescription : @"";
}

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
+ (void)getAlbumsWithCompletionBlock:(void (^)(NSArray *albums))completion
{
    [[[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"/%@/albums", [FBSDKProfile currentProfile].userID]
                                       parameters:nil
                                       HTTPMethod:@"GET"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                                                       id result,
                                                                                       NSError *error){
        if(!error){
            NSDictionary *resultDictionary = result;
            
            NSMutableArray *albums = [@[] mutableCopy];
            for(NSDictionary *albumData in resultDictionary[@"data"]){
                [albums addObject:[[FacebookAlbum alloc] initWithData:albumData]];
            }
            
            completion(albums);
        }else{
            completion(nil);
        }
    }];
}

+ (void)getPhotosInAlbum:(FacebookAlbum *)album
     withCompletionBlock:(void (^)(NSArray *photos))completion;
{
    [[[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"/%@/photos", album.albumId]
                                       parameters:nil
                                       HTTPMethod:@"GET"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                                                       id result,
                                                                                       NSError *error) {
        if(!error){
            NSDictionary *resultDictionary = result;
            
            NSMutableArray *photos = [@[] mutableCopy];
            for(NSDictionary *photoData in resultDictionary[@"data"]){
                [photos addObject:[[FacebookPhoto alloc] initWithData:photoData]];
            }
            
            completion(photos);
        }else{
            completion(nil);
        }
    }];
    
}

- (FacebookAlbum *)initWithData:(NSDictionary *)data
{
    if(self = [super init]){
        self.albumId            = data[@"id"];
        self.albumName          = data[@"name"];
        self.albumDescription   = data[@"description"];
        self.albumCoverPhotoId  = data[@"cover_photo"];
        self.albumImageCount    = [data[@"count"] intValue];
    }
    return self;
}

- (void)getAlbumCoverPhotoWithCompletionBlock:(void (^)())completion
{
    [[[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"/%@", self.albumCoverPhotoId]
                                       parameters:@{@"type": @"thumbnail"}
                                       HTTPMethod:@"GET"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                                                       id result,
                                                                                       NSError *error) {
        dispatch_async(dispatch_queue_create("get fb image", NULL), ^{
            if(!error){
                NSDictionary *data = result;
                
                NSString *imageSource;
                CGSize imageSize;
                CGFloat imageDelta = MAXFLOAT;
                
                for(NSDictionary *imageData in data[@"images"]){
                    NSString *source = imageData[@"source"];
                    CGFloat width = [imageData[@"width"] doubleValue];
                    CGFloat height = [imageData[@"height"] doubleValue];
                    CGSize size = CGSizeMake(width, height);

                    CGFloat thisDelta = width - WIDTH_GOAL;
                    
                    if(!imageSource){
                        imageSource = source;
                        imageSize = size;
                        imageDelta = thisDelta;
                    }
                    
                    //our goal will be that the delta is as small as possible, but positive.
                    if(((imageDelta < 0) && (thisDelta > 0))                                            //if we're negative but we can become positive
                       ||                                                                               //or
                       ((thisDelta > 0) && (thisDelta < imageDelta))                                    //we found a smaller delta that remains positive
                       ||                                                                               //or
                       ((imageDelta < 0) && (thisDelta < 0) && (thisDelta > imageDelta))){              //they're both negative, but we can reduce the delta
                        imageSource = source;
                        imageSize = size;
                        
                        imageDelta = thisDelta;
                    }
                }
                
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageSource]]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.albumCoverCache = image;
                    completion();
                });
            }else{
                completion();
            }
        });
    }];
}

#pragma mark Helper Functions
#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - UIViewController Overrides

@end
