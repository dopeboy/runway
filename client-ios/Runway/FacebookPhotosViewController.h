//
//  FacebookPhotosViewController.h
//  Runway
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FacebookAlbum;

@interface FacebookPhotosViewController : UICollectionViewController

- (void)setupWithAlbum:(FacebookAlbum *)album;

@end
