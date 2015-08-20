//
//  AccessCodeViewController.h
//  Runway
//
//  Created by Roberto Cordon on 8/12/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AccessCodeDelegate <NSObject>
- (void)accessCodeEntered:(NSString *)code;
@end

@interface AccessCodeViewController : UIViewController

- (void)setupWithDelegate:(id<AccessCodeDelegate>)delegate
               andMessage:(NSString *)message;
@end
