//
//  HelpView.h
//  Runway
//
//  Created by Roberto Cordon on 8/16/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpView : UIView

+ (HelpView *)showIfApplicableInsideOfView:(UIView *)superview
                           usingImageNamed:(NSString *)imageNamed
                             andHelpViewId:(NSInteger)helpViewId;

@end
