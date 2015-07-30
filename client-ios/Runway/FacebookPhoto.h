//
//  FacebookPhoto.h
//  FacebookTest
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FacebookPhoto : NSObject

@property (nonatomic, strong) UIImage *photoCache;
@property (nonatomic, strong) UIImage *photoThumbnailCache;
@property (nonatomic, strong) UIImage *photoThumbnailToUploadCache;

- (FacebookPhoto *)initWithData:(NSDictionary *)data;
- (FacebookPhoto *)initWithImageFromDevice:(UIImage *)image;
- (void)getPhotoThumbnailsWithCompletionBlock:(void (^)())completion;
- (void)getPhotoWithCompletionBlock:(void (^)())completion;

@end
