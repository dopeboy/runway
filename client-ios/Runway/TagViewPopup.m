//
//  TagViewPopup.m
//  Runway
//
//  Created by Roberto Cordon on 9/1/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "TagViewPopup.h"
#import "CommonConstants.h"

#define HEIGHT      50
#define PADDING     20      //should be bigger than the radius
#define RADIUS      12      //ideally, matches CIRCLE_RADIUS

@interface TagViewPopup()
@property (nonatomic) CGRect hideFrame;
@property (nonatomic, weak) UILabel *label;

@end

@implementation TagViewPopup

- (void)showInsideOfView:(UIView *)superview
     originatingFromRect:(CGRect)sourceRect
                withText:(NSString *)text
{
    self.layer.cornerRadius = RADIUS;
    self.backgroundColor = GREEN_COLOR;
    self.hideFrame = sourceRect;
    
    CGRect destinationFrame;
    destinationFrame.size.height = HEIGHT;
    destinationFrame.size.width = PADDING + PADDING + [text sizeWithAttributes:@{NSFontAttributeName:self.fontForDialog}].width;
    destinationFrame.origin.x = (superview.frame.size.width - destinationFrame.size.width) / 2;
    destinationFrame.origin.y = sourceRect.origin.y - PADDING - HEIGHT;
    if(destinationFrame.origin.y < PADDING){
        destinationFrame.origin.y = sourceRect.origin.y + sourceRect.size.height + PADDING;
    }
    
    self.frame = sourceRect;
    [superview addSubview:self];

    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = self.fontForDialog;
    label.text = text;
    label.alpha = 0;
    [self addSubview:label];
    self.label = label;

    [UIView animateWithDuration:ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.frame = destinationFrame;
                         
                         CGRect labelFrame = destinationFrame;
                         labelFrame.origin = CGPointZero;
                         self.label.frame = labelFrame;
                         label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                     }
                     completion:^(BOOL finished){
                         if(finished && CGRectEqualToRect(self.frame, destinationFrame)){
                             [UIView animateWithDuration:(ANIMATION_DURATION / 2)
                                                   delay:0
                                                 options:UIViewAnimationOptionBeginFromCurrentState
                                              animations:^{
                                                  self.label.alpha = 1;
                                              }
                                              completion:nil];
                         }
                         
                     }];
}

- (void)hide
{
    [UIView animateWithDuration:(ANIMATION_DURATION / 2)
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.label.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         if(finished){
                             [UIView animateWithDuration:ANIMATION_DURATION
                                                   delay:0
                                                 options:UIViewAnimationOptionBeginFromCurrentState
                                              animations:^{
                                                  self.frame = self.hideFrame;
                                              }
                                              completion:^(BOOL finished){
                                                  [self removeFromSuperview];
                                              }];
                         }
                     }];
}

- (UIFont *)fontForDialog
{
    return FONT(14);
}

@end
