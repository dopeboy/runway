//
//  SideMenuViewController.m
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "SideMenuViewController.h"

#import "SWRevealViewController.h"
#import "ImageListViewController.h"
#import "SwiperViewController.h"
#import "SideMenuCell.h"

#import "CommonConstants.h"
#import "StringConstants.h"

#define ASSET_BROWSE                    @"sideMenuBrowse.png"
#define ASSET_MY_PICTURES               @"sideMenuMyPictures.png"
#define ASSET_FAVORITES                 @"sideMenuFavorites.png"
#define ASSET_LEADERBOARD               @"sideMenuLeaderboard.png"
#define ASSET_SIGN_OUT                  @"sideMenuSignOut.png"

#define BROWSE_SEGUE_IDENTIFIER         @"browse segue"
#define IMAGE_LIST_SEGUE_IDENTIFIER     @"image list segue"

@interface SideMenuViewController () <SideMenuCellDelegate>
@property (nonatomic) NSInteger lastCellIndexSelected;

@property (nonatomic, strong) NSArray *menuTitles;
@property (nonatomic, strong) NSArray *menuAssets;
@end

@implementation SideMenuViewController

#pragma mark - Getters/Setters
#pragma mark Public Functions

#pragma mark Helper Functions
#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers

////////////////////////////////////////////////////////////////////////
//
// UITableViewDataSource Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource Implementation
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"menuCell";
    SideMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    [cell setupWithTitle:self.menuTitles[indexPath.row]
            andAssetName:self.menuAssets[indexPath.row]
                 atIndex:indexPath.row
            withDelegate:self];
    
    return cell;
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewDelegate Implementation
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.lastCellIndexSelected == indexPath.row){
        //no change, just hide menu
        [self.revealViewController revealToggle:self];
    }else{
        NSIndexPath *oldIP = [NSIndexPath indexPathForRow:self.lastCellIndexSelected inSection:0];
        self.lastCellIndexSelected = indexPath.row;

        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIP];
        oldCell.selected = NO;

        if(self.lastCellIndexSelected == 0){
            //browse
            self.lastCellIndexSelected = indexPath.row;
            [self performSegueWithIdentifier:BROWSE_SEGUE_IDENTIFIER sender:@(indexPath.row)];
        }else if(self.lastCellIndexSelected == 4){
            [self.navigationController popToRootViewControllerAnimated:YES];
        }else{
            //image list
            self.lastCellIndexSelected = indexPath.row;
            [self performSegueWithIdentifier:IMAGE_LIST_SEGUE_IDENTIFIER sender:@(indexPath.row)];
        }
    }
}

////////////////////////////////////////////////////////////////////////
//
// SideMenuCellDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark SideMenuCellDelegate Implementation
- (BOOL)isSelectedWithIndex:(NSInteger)index
{
    return (self.lastCellIndexSelected == index);
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewController Overrides
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewController Overrides
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lastCellIndexSelected = 0; //we always start in browse
    
    self.menuTitles = @[
                        STR_SIDE_MENU_BROWSE,
                        STR_SIDE_MENU_MY_PICTURES,
                        STR_SIDE_MENU_FAVORITES,
                        STR_SIDE_MENU_LEADERBOARD,
                        STR_SIDE_MENU_SIGNOUT,
                        ];
    
    self.menuAssets = @[
                        ASSET_BROWSE,
                        ASSET_MY_PICTURES,
                        ASSET_FAVORITES,
                        ASSET_LEADERBOARD,
                        ASSET_SIGN_OUT,
                        ];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.separatorInset = self.tableView.layoutMargins = UIEdgeInsetsZero;
    self.tableView.backgroundColor = self.view.backgroundColor = GREEN_COLOR;
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:IMAGE_LIST_SEGUE_IDENTIFIER]){
        UINavigationController *navVC = segue.destinationViewController;
        ImageListViewController *vc = (ImageListViewController *)navVC.topViewController;

        t_ImageListType listType =  (self.lastCellIndexSelected == 1) ? ImageListTypeMyImages    :
                                    (self.lastCellIndexSelected == 2) ? ImageListTypeFavorites   :
                                    (self.lastCellIndexSelected == 3) ? ImageListTypeLeaderboard : INVALID_INDEX;
        [vc setupListOfType:listType usingTitle:self.menuTitles[self.lastCellIndexSelected]];
    }else if([segue.identifier isEqualToString:BROWSE_SEGUE_IDENTIFIER]){
        UINavigationController *navVC = segue.destinationViewController;
        SwiperViewController *vc = (SwiperViewController *)navVC.topViewController;

        [vc setupWithImage:nil
                allowSwipe:YES
                 allowEdit:NO
               allowVoting:YES];
    }
}

@end
