//
//  TagDetailsPickerViewController.h
//  Runway
//
//  Created by Roberto Cordon on 6/1/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TagDetailsPickerDelegate <NSObject>
- (void)choseBrandWithGUID:(NSString *)brandGUID;
- (void)choseTypeWithGUID:(NSString *)typeGUID;
@end

@interface TagDetailsPickerViewController : UITableViewController

- (void)setupBrandListUsingDelegate:(id<TagDetailsPickerDelegate>)delegate
                    withDefaultGUID:(NSString *)defaultGUID;

- (void)setupTypeListUsingDelegate:(id<TagDetailsPickerDelegate>)delegate
                   withDefaultGUID:(NSString *)defaultGUID;
@end
