//
//  RoundButton.m
//  Runway
//
//  Created by Roberto Cordon on 8/14/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "RoundButton.h"

@implementation RoundButton

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.layer.cornerRadius = (self.frame.size.height / 2);
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.layer.cornerRadius = (self.bounds.size.height / 2);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = (self.frame.size.height / 2);
}

@end
