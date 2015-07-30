//
//  SwiperView.h
//  Runway
//
//  Created by Roberto Cordon on 5/25/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagView.h"

@class Image;
@class SwiperView;
@class Tag;

@protocol SwiperDelegate <NSObject>
- (void)swipedOutSwiperView:(SwiperView *)swiperView;
- (void)editPropertiesForTag:(Tag *)tag;
- (void)swiperView:(SwiperView *)swiperView updatedSwipedPercent:(CGFloat)percent;
@end

@interface SwiperView : UIView <TagDelegate>

@property (nonatomic, strong) Image *image;
@property (nonatomic) BOOL gestureEnabled;
@property (nonatomic) BOOL editing;
@property (nonatomic) CGFloat blur;
@property (nonatomic) CGPoint scaleFactor;

- (SwiperView *)initWithImage:(Image *)image
                   allowSwipe:(BOOL)allowSwipe
                    allowEdit:(BOOL)allowEdit
                  allowVoting:(BOOL)allowVoting
                      toFitIn:(CGSize)size
                usingDelegate:(id<SwiperDelegate>)delegate
                     andTable:(UITableView *)tableForReasons;

- (SwiperView *)initWithNoImageAndAllowSwipe:(BOOL)allowSwipe
                                   allowEdit:(BOOL)allowEdit
                                 allowVoting:(BOOL)allowVoting
                                     toFitIn:(CGSize)size
                               usingDelegate:(id<SwiperDelegate>)delegate
                                    andTable:(UITableView *)tableForReasons;

- (void)forceSwipeOut;
- (void)removeTagViewForTag:(Tag *)tag;
@end
