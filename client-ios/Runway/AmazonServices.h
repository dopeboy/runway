//
//  AmazonServices.h
//  Runway
//
//  Created by Roberto Cordon on 7/8/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AmazonServices : NSObject

+ (BOOL)uploadFullImage:(UIImage *)fullImage
      andThumbnailImage:(UIImage *)thumbnailImage
               withUUID:(NSString *)uuid;

+ (UIImage *)downloadFullImageWithUUID:(NSString *)uuid;
+ (UIImage *)downloadThumbImageWithUUID:(NSString *)uuid;

@end
