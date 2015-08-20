//
//  HelpView.m
//  Runway
//
//  Created by Roberto Cordon on 8/16/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "HelpView.h"

#define HELP_VIEW_SHOWN_KEY     @"help view shown"

@interface HelpView()
@property (nonatomic, strong) NSNumber *helpViewId;
@end

@implementation HelpView

+ (HelpView *)showIfApplicableInsideOfView:(UIView *)superview
                           usingImageNamed:(NSString *)imageName
                             andHelpViewId:(NSInteger)helpViewId
{
#warning comment the line below out
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:HELP_VIEW_SHOWN_KEY];
    
    HelpView *h = [[HelpView alloc] init];
    [h showIfApplicableInsideOfView:superview usingImageNamed:imageName andHelpViewId:helpViewId];
    return h;
}

- (void)showIfApplicableInsideOfView:(UIView *)superview
                     usingImageNamed:(NSString *)imageName
                       andHelpViewId:(NSInteger)helpViewId
{
    self.helpViewId = @(helpViewId);
    NSArray *shownViews = [[NSUserDefaults standardUserDefaults] objectForKey:HELP_VIEW_SHOWN_KEY];
    if(![shownViews containsObject:self.helpViewId]){
        CGRect frame = superview.frame;
        frame.origin = CGPointZero;
        self.frame = frame;
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        
        UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        CGRect imageFrame = image.frame;
        imageFrame.origin.x = (self.frame.size.width - imageFrame.size.width) / 2;
        imageFrame.origin.y = self.frame.size.height - imageFrame.size.height;
        image.frame = imageFrame;
        image.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:image];
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSelf)]];
        
        [superview addSubview:self];
    }
}

- (void)dismissSelf
{
    NSMutableArray *shownViews = [[[NSUserDefaults standardUserDefaults] objectForKey:HELP_VIEW_SHOWN_KEY] mutableCopy];
    if(!shownViews) shownViews = [NSMutableArray array];
    
    [shownViews addObject:self.helpViewId];
    [[NSUserDefaults standardUserDefaults] setObject:shownViews forKey:HELP_VIEW_SHOWN_KEY];

    [UIView animateWithDuration:0.3
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         [self removeFromSuperview];
                     }
     ];
    
}



@end
