//
//  FacebookPhotoCell.m
//  Runway
//
//  Created by Roberto Cordon on 6/3/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "FacebookPhotoCell.h"
#import "FacebookPhoto.h"

@interface FacebookPhotoCell()

@property (nonatomic, strong) FacebookPhoto *photo;

@property (nonatomic, strong) IBOutlet UIImageView *image;
@property (nonatomic ,weak) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation FacebookPhotoCell

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupWithPhoto:(FacebookPhoto *)photo
{
    self.photo = photo;
    
    if(photo.photoThumbnailCache){
        [self setImagePreview:photo.photoThumbnailCache];
    }else{
        [self setImagePreview:nil];
        
        [photo getPhotoThumbnailsWithCompletionBlock:^{
            if(self.photo == photo){
                [self setImagePreview:photo.photoThumbnailCache];
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
- (void)setImagePreview:(UIImage *)image
{
    if(image){
        [self.spinner stopAnimating];
        self.image.hidden = NO;
        self.image.image = image;
    }else{
        [self.spinner startAnimating];
        self.image.hidden = YES;
    }
}

#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark UICollectionViewDelegate Implementation
#pragma mark - UICollectionViewCell Overrides

@end
