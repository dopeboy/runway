//
//  SwiperViewController.h
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Image;
@class FacebookPhoto;
@interface SwiperViewController : UIViewController

- (void)setupWithImage:(Image *)image
            allowSwipe:(BOOL)allowSwipe
             allowEdit:(BOOL)allowEdit
           allowVoting:(BOOL)allowVoting;

- (void)setupWithFacebookPhoto:(FacebookPhoto *)photo;

- (void)addBackButton;

@end
