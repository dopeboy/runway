//
//  FacebookPhoto.m
//  FacebookTest
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "FacebookPhoto.h"
#import "CommonConstants.h"

#define THUMBNAIL_WIDTH_GOAL    100
#define FULL_WIDTH_GOAL         SWIPER_VIEW_WIDTH_UNSCALED

@interface FacebookPhoto()
@property (nonatomic, strong) NSString *photoId;
@property (nonatomic, strong) NSString *photoSource;
@property (nonatomic, strong) NSString *photoThumbnailSource;
@property (nonatomic) CGSize photoSize;
@property (nonatomic) CGSize photoThumbnailSize;
@end

@implementation FacebookPhoto

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (FacebookPhoto *)initWithData:(NSDictionary *)data
{
    if(self = [super init]){
        self.photoId = data[@"id"];
        
        CGFloat fullDelta = MAXFLOAT;
        CGFloat thumbDelta = MAXFLOAT;
        
        for(NSDictionary *imageData in data[@"images"]){
            NSString *source = imageData[@"source"];
            CGFloat width = [imageData[@"width"] doubleValue];
            CGFloat height = [imageData[@"height"] doubleValue];
            CGSize size = CGSizeMake(width, height);

            CGFloat thisFullDelta = width - FULL_WIDTH_GOAL;
            CGFloat thisThumbDelta = width - THUMBNAIL_WIDTH_GOAL;
            
            if(!self.photoSource || !self.photoThumbnailSource){
                self.photoSource = self.photoThumbnailSource = source;
                self.photoSize = self.photoThumbnailSize = size;
                
                fullDelta = thisFullDelta;
                thumbDelta = thisThumbDelta;
            }

            //our goal will be that the delta is as small as possible, but positive.
            if(((fullDelta < 0) && (thisFullDelta > 0))                                         //if we're negative but we can become positive
               ||                                                                               //or
               ((thisFullDelta > 0) && (thisFullDelta < fullDelta))                             //we found a smaller delta that remains positive
               ||                                                                               //or
               ((fullDelta < 0) && (thisFullDelta < 0) && (thisFullDelta > fullDelta))){        //they're both negative, but we can reduce the delta
                self.photoSource = source;
                self.photoSize = size;
                
                fullDelta = thisFullDelta;
            }

            if(((thumbDelta < 0) && (thisThumbDelta > 0))                                       //if we're negative but we can become positive
               ||                                                                               //or
               ((thisThumbDelta > 0) && (thisThumbDelta < thumbDelta))                          //we found a smaller delta that remains positive
               ||                                                                               //or
               ((thumbDelta < 0) && (thisThumbDelta < 0) && (thisThumbDelta > thumbDelta))){    //they're both negative, but we can reduce the delta
                self.photoThumbnailSource = source;
                self.photoThumbnailSize = size;
                
                thumbDelta = thisThumbDelta;
            }
        }
    }
    return self;
}

- (FacebookPhoto *)initWithImageFromDevice:(UIImage *)image;
{
    if(self = [super init]){
        self.photoCache = image;

        CGFloat thumbnailWHFactor = 345.0 / 124.0;  //numbers from ios6 simulator
        CGRect thumbnailCropRect;
        thumbnailCropRect.origin = CGPointZero;
        thumbnailCropRect.size.width  = self.photoCache.size.width;
        thumbnailCropRect.size.height = self.photoCache.size.width / thumbnailWHFactor;

        CGImageRef imageRef = CGImageCreateWithImageInRect([self.photoCache CGImage], thumbnailCropRect);
        self.photoThumbnailToUploadCache = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }

    return self;
}

- (void)getPhotoWithCompletionBlock:(void (^)())completion
{
    dispatch_async(dispatch_queue_create("get fb image", NULL), ^{
        [self fetchFullFacebookPhoto];

        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
}

- (void)getPhotoThumbnailsWithCompletionBlock:(void (^)())completion
{
    dispatch_async(dispatch_queue_create("get fb image", NULL), ^{
        ////////////////////////////////////
        // get the thumbnail for the picker
        ////////////////////////////////////
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.photoThumbnailSource]]];
        self.photoThumbnailCache = image;

        ///////////////////////////////
        // get the thumbnail to upload
        ///////////////////////////////
        if(!self.photoCache) [self fetchFullFacebookPhoto];
        
        //calculate the crop rect (for now, origin is 0, 0)
        CGFloat thumbnailWHFactor = 345.0 / 124.0;  //numbers from ios6 simulator
        CGRect thumbnailCropRect;
        thumbnailCropRect.origin = CGPointZero;
        thumbnailCropRect.size.width  = self.photoCache.size.width;
        thumbnailCropRect.size.height = self.photoCache.size.width / thumbnailWHFactor;
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([self.photoCache CGImage], thumbnailCropRect);
        self.photoThumbnailToUploadCache = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);

        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (void)fetchFullFacebookPhoto
{
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.photoSource]]];
    self.photoCache = image;
}

#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - UIViewController Overrides

@end
