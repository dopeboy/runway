//
//  TagDetailsPickerViewController.m
//  Runway
//
//  Created by Roberto Cordon on 6/1/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "TagDetailsPickerViewController.h"
#import "Clothing.h"
#import "Brand.h"

#import "CommonConstants.h"

typedef enum{
    TagDetailBrand,
    TagDetailClothingType,
}t_TagDetail;

@interface TagDetailsPickerViewController ()
@property (nonatomic) t_TagDetail detailType;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSString *defaultGUID;
@property (nonatomic, weak) id<TagDetailsPickerDelegate> delegate;
@end

@implementation TagDetailsPickerViewController

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupBrandListUsingDelegate:(id<TagDetailsPickerDelegate>)delegate
                    withDefaultGUID:(NSString *)defaultGUID
{
    self.detailType = TagDetailBrand;
    self.delegate = delegate;
    self.defaultGUID = defaultGUID;
}

- (void)setupTypeListUsingDelegate:(id<TagDetailsPickerDelegate>)delegate
                   withDefaultGUID:(NSString *)defaultGUID
{
    self.detailType = TagDetailClothingType;
    self.delegate = delegate;
    self.defaultGUID = defaultGUID;
}

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
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"dataCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if(self.detailType == TagDetailBrand){
        Brand *b = self.data[indexPath.row];
        cell.textLabel.text = b.name;
        cell.accessoryType = ([self.defaultGUID isEqualToString:b.GUID]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }else if(self.detailType == TagDetailClothingType){
        Clothing *c = self.data[indexPath.row];
        cell.textLabel.text = c.name;
        cell.accessoryType = ([self.defaultGUID isEqualToString:c.GUID]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.backgroundColor = cell.contentView.backgroundColor = [UIColor blackColor];
    cell.textLabel.font = FONT(16);
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.tintColor = GREEN_COLOR;
    
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
    if(self.detailType == TagDetailBrand){
        Brand *b = self.data[indexPath.row];
        [self.delegate choseBrandWithGUID:b.GUID];
    }else if(self.detailType == TagDetailClothingType){
        Clothing *c = self.data[indexPath.row];
        [self.delegate choseTypeWithGUID:c.GUID];
    }
}

////////////////////////////////////////////////////////////////////////
//
// UIViewController Overrides
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController Overrides
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"Select an Item";
    self.view.backgroundColor = self.tableView.backgroundColor = [UIColor blackColor];

    dispatch_async(dispatch_queue_create("get tag detail options", NULL), ^{
        if(self.detailType == TagDetailBrand){
            self.data = [Brand getTypesAndNames];
        }else if(self.detailType == TagDetailClothingType){
            self.data = [Clothing getTypesAndNames];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

@end
