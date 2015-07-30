//
//  EditTagDetailsViewController.h
//  Runway
//
//  Created by Roberto Cordon on 6/1/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Tag;

@protocol EditTagDetailsDelegate <NSObject>

- (void)cancelledEditingDetailsForTag:(Tag *)tag;

@end

@interface EditTagDetailsViewController : UIViewController
- (void)setupForTag:(Tag *)tag
       withDelegate:(id<EditTagDetailsDelegate>)delegate;
@end
