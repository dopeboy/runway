//
//  ImageListViewController.h
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    ImageListTypeMyImages,
    ImageListTypeFavorites,
    ImageListTypeLeaderboard,
}t_ImageListType;

@interface ImageListViewController : UITableViewController

- (void)setupListOfType:(t_ImageListType)listType
             usingTitle:(NSString *)title;

- (void)refreshTable;

@end
