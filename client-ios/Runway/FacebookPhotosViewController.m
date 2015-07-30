//
//  FacebookPhotosViewController.m
//  Runway
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "FacebookPhotosViewController.h"
#import "FacebookAlbum.h"
#import "FacebookPhoto.h"
#import "FacebookPhotoCell.h"

#import "SwiperViewController.h"

#define ADD_PHOTO_SEGUE_NAME        @"add photo segue"

@interface FacebookPhotosViewController ()

@property (nonatomic, strong) NSArray *photos;
@end

@implementation FacebookPhotosViewController

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupWithAlbum:(FacebookAlbum *)album
{
    [FacebookAlbum getPhotosInAlbum:album withCompletionBlock:^(NSArray *photos){
        self.photos = photos;
        [self.collectionView reloadData];
    }];
}

#pragma mark Helper Functions
#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers

////////////////////////////////////////////////////////////////////////
//
// UICollectionViewDataSource Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UICollectionViewDataSource Implementation
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"photoCell";
    FacebookPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [cell setupWithPhoto:self.photos[indexPath.row]];
    
    return cell;
}

////////////////////////////////////////////////////////////////////////
//
// UICollectionViewDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark UICollectionViewDelegate Implementation
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:ADD_PHOTO_SEGUE_NAME sender:self.photos[indexPath.row]];
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewController Overrides
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewController Overrides
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:ADD_PHOTO_SEGUE_NAME]){
        SwiperViewController *vc = segue.destinationViewController;
        [vc setupWithFacebookPhoto:sender];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Photos";
}

@end
