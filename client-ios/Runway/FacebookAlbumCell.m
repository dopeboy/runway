//
//  FacebookAlbumCell.m
//  Runway
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "FacebookAlbumCell.h"
#import "FacebookAlbum.h"

#import "CommonConstants.h"
#import "StringConstants.h"

@interface FacebookAlbumCell()

@property (nonatomic, strong) FacebookAlbum *album;

@property (nonatomic, weak) IBOutlet UIImageView *imageAlbumCover;
@property (nonatomic ,weak) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, weak) IBOutlet UILabel *labelAlbumTitle;
@property (nonatomic, weak) IBOutlet UILabel *labelPhotoCount;

@end

@implementation FacebookAlbumCell

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupWithAlbum:(FacebookAlbum *)album
{
    self.album = album;
    
    self.labelAlbumTitle.text = album.albumName;
    self.labelPhotoCount.text = [NSString stringWithFormat:STR_FACEBOOK_ALBUM_IMAGE_COUNT_FMT, album.albumImageCount];
    self.imageAlbumCover.layer.borderWidth = 0.5;
    self.imageAlbumCover.layer.borderColor = GREEN_COLOR.CGColor;

    if(album.albumCoverCache){
        [self setAlbumCover:album.albumCoverCache];
    }else{
        [self setAlbumCover:nil];
        
        [album getAlbumCoverPhotoWithCompletionBlock:^{
            if(self.album == album){
                [self setAlbumCover:album.albumCoverCache];
            }
        }];
    }
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (void)setAlbumCover:(UIImage *)image
{
    if(image){
        [self.spinner stopAnimating];
        self.imageAlbumCover.hidden = NO;
        self.imageAlbumCover.image = image;
    }else{
        [self.spinner startAnimating];
        self.imageAlbumCover.hidden = YES;
    }
}

#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - NSObject Overrides

@end
