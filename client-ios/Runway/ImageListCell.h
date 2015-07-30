//
//  ImageListCell.h
//  Runway
//
//  Created by Roberto Cordon on 5/25/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Image;
@interface ImageListCell : UITableViewCell

- (void)setupWithImage:(Image *)image
      andShowKarmaInfo:(BOOL)showKarmaInfo;

@end
