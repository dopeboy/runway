//
//  CenteredLabel.m
//  Runway
//
//  Created by Roberto Cordon on 8/14/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "CenteredLabel.h"

@implementation CenteredLabel

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if(self.superview){
        CGSize size = self.superview.frame.size;
        self.center = CGPointMake(size.width / 2, size.height / 2);
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
}

@end
