//
//  SideMenuCell.h
//  Runway
//
//  Created by Roberto Cordon on 7/13/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol SideMenuCellDelegate <NSObject>
- (BOOL)isSelectedWithIndex:(NSInteger)index;
@end

@interface SideMenuCell : UITableViewCell

- (void)setupWithTitle:(NSString *)title
          andAssetName:(NSString *)assetName
               atIndex:(NSInteger)cellIndex
          withDelegate:(id<SideMenuCellDelegate>)delegate;

@end
