//
//  DownvoteReasonsView.h
//  Runway
//
//  Created by Roberto Cordon on 5/28/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Tag;
@class TagView;

@interface DownvoteReasonsView : UIView

+ (void)createInstanceInSuperview:(UIView *)superview
                           forTag:(Tag *)tag
                          andView:(TagView *)tagView
                        withTable:(UITableView *)table
                         andTitle:(NSString *)title
                 showingStatsOnly:(BOOL)showStats;

@end
