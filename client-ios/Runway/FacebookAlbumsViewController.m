//
//  FacebookAlbumsViewController.m
//  Runway
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "FacebookAlbumsViewController.h"
#import "FacebookAlbumCell.h"
#import "FacebookAlbum.h"
#import "FacebookPhotosViewController.h"

#define VIEW_PHOTOS_SEGUE       @"view album segue"


@interface FacebookAlbumsViewController ()
@property (nonatomic, strong) NSArray *albums;
@end

@implementation FacebookAlbumsViewController


////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
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
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"albumCell";
    FacebookAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    [cell setupWithAlbum:self.albums[indexPath.row]];
    
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
    [self performSegueWithIdentifier:VIEW_PHOTOS_SEGUE sender:self.albums[indexPath.row]];
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewController Overrides
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewController Overrides
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Albums";
    
    [FacebookAlbum getAlbumsWithCompletionBlock:^(NSArray *albums){
        self.albums = albums;
        [self.tableView reloadData];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:VIEW_PHOTOS_SEGUE]){
        FacebookPhotosViewController *vc = segue.destinationViewController;
        [vc setupWithAlbum:sender];
    }
}

@end
