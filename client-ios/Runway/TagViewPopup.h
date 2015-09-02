//
//  TagViewPopup.h
//  Runway
//
//  Created by Roberto Cordon on 9/1/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TagViewPopup : UIView

- (void)showInsideOfView:(UIView *)superview
     originatingFromRect:(CGRect)sourceRect
                withText:(NSString *)text;

- (void)hide;

@end
