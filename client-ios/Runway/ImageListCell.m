//
//  ImageListCell.m
//  Runway
//
//  Created by Roberto Cordon on 5/25/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "ImageListCell.h"
#import "Image.h"

#import "CommonConstants.h"

#define IMAGE_DIMENSION     64

@interface ImageListCell()
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, weak) IBOutlet UIImageView *imageThumbnail;
@property (nonatomic, weak) IBOutlet UIImageView *imageUp;
@property (nonatomic, weak) IBOutlet UIImageView *imageDown;
@property (nonatomic, weak) IBOutlet UILabel *labelText;
@property (nonatomic, weak) IBOutlet UILabel *labelUp;
@property (nonatomic, weak) IBOutlet UILabel *labelDown;

@property (nonatomic, strong) Image *image;
@property (nonatomic, strong) Image *fetchingImage;
@end

@implementation ImageListCell

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupWithImage:(Image *)image
      andShowKarmaInfo:(BOOL)showKarmaInfo
{
    self.image = image;
    
    self.labelText.text = image.title;
    
    self.imageUp.hidden = self.imageDown.hidden = self.labelUp.hidden = self.labelDown.hidden = !showKarmaInfo;
    if(showKarmaInfo){
        self.labelUp.text = [NSString stringWithFormat:@"%i", image.upvotes];
        self.labelDown.text = [NSString stringWithFormat:@"%i", image.downvotes];
    }
    
    if(image.thumbnailImageAvailable){
        [self.spinner stopAnimating];
        [self setThumbnailImage:image.thumbnailImage];
    }else{
        self.spinner.center = self.imageView.center;
        [self.spinner startAnimating];
        [self setThumbnailImage:nil];

        if(self.fetchingImage != self.image){
            self.fetchingImage = self.image;
            
            dispatch_async(dispatch_queue_create("image getter", NULL), ^{
                UIImage *tmpImg = image.thumbnailImage;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.spinner stopAnimating];
                    
                    //check that it's still relevant
                    if(self.image == image){
                        [self setThumbnailImage:tmpImg];
                    }
                    
                    self.fetchingImage = nil;
                });
            });
        }
    }
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (void)setThumbnailImage:(UIImage *)thumb
{
    self.imageThumbnail.backgroundColor = [UIColor grayColor];
    self.imageThumbnail.image = thumb;
    
}

#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
////////////////////////////////////////////////////////////////////////
//
// UITableViewCell Overrides
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewCell Overrides
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShadow(context, CGSizeMake(-2, 2), 10);
    CGContextFillRect(context, self.imageThumbnail.frame);
}

@end
