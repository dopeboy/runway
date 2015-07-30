//
//  SideMenuCell.m
//  Runway
//
//  Created by Roberto Cordon on 7/13/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "SideMenuCell.h"
#import "CommonConstants.h"

#define BG_TAG                          455

@interface SideMenuCell()
@property (nonatomic, weak) id<SideMenuCellDelegate> delegate;
@property (nonatomic) NSInteger cellIndex;
@end

@implementation SideMenuCell

- (void)setupWithTitle:(NSString *)title
          andAssetName:(NSString *)assetName
               atIndex:(NSInteger)cellIndex
          withDelegate:(id<SideMenuCellDelegate>)delegate
{
    self.delegate = delegate;
    self.cellIndex = cellIndex;
    
    if(self.selectedBackgroundView.tag != BG_TAG){
        self.selectedBackgroundView = [[UIView alloc] init];
        self.selectedBackgroundView.tag = BG_TAG;
        self.selectedBackgroundView.backgroundColor = [UIColor whiteColor];

        self.textLabel.font = FONT(21);
        
        self.separatorInset = self.layoutMargins = UIEdgeInsetsZero;
    }
    
    self.textLabel.text = title;
    self.imageView.image = [UIImage imageNamed:assetName];
    self.selected = NO; //it doesn't matter if yes/no, the setter overrides it.
}

- (void)setSelected:(BOOL)selected
{
    BOOL realSelected = [self.delegate isSelectedWithIndex:self.cellIndex];
    
    [super setSelected:realSelected];
    self.highlighted = realSelected;
    self.textLabel.textColor = realSelected ? [UIColor blackColor] : [UIColor whiteColor];
}

@end
