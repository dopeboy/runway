//
//  EditTagDetailsViewController.m
//  Runway
//
//  Created by Roberto Cordon on 6/1/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "EditTagDetailsViewController.h"
#import "TagDetailsPickerViewController.h"

#import "Tag.h"
#import "Clothing.h"
#import "Brand.h"

#import "CommonConstants.h"
#import "StringConstants.h"

#define TYPE_SEGUE_NAME         @"typeSegue"
#define BRAND_SEGUE_NAME        @"brandSegue"

@interface EditTagDetailsViewController () <TagDetailsPickerDelegate>
@property (nonatomic, weak) id<EditTagDetailsDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, weak) IBOutlet UIButton *typeButton;
@property (nonatomic, weak) IBOutlet UIButton *brandButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

@property (nonatomic, strong) Tag *tagObject;
@end

@implementation EditTagDetailsViewController

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupForTag:(Tag *)tag
       withDelegate:(id<EditTagDetailsDelegate>)delegate
{
    self.tagObject = tag;
    self.delegate = delegate;
}

#pragma mark Helper Functions

////////////////////////////////////////////////////////////////////////
//
// IBAction Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark - IBAction Handlers
- (void)doneButtonPressed
{
    self.navigationItem.leftBarButtonItem = nil;
    self.typeButton.hidden = self.brandButton.hidden = YES;
    [self.spinner startAnimating];

    dispatch_async(dispatch_queue_create("get tag details", NULL), ^{
        [self.tagObject saveEditChanges];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

- (void)cancelButtonPressed
{
    self.navigationItem.leftBarButtonItem = nil;
    self.typeButton.hidden = self.brandButton.hidden = YES;
    [self.spinner startAnimating];

    [self.delegate cancelledEditingDetailsForTag:self.tagObject];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Gesture Handlers

////////////////////////////////////////////////////////////////////////
//
// TagDetailsPickerDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - TagDetailsPickerDelegate Implementation
- (void)choseBrandWithGUID:(NSString *)brandGUID
{
    self.tagObject.brandGUID = brandGUID;
    [self.navigationController popToViewController:self animated:YES];
    
    if(self.tagObject.clothingGUID.length && self.tagObject.brandGUID.length){
        self.navigationItem.leftBarButtonItem = self.doneButton;
    }
}
- (void)choseTypeWithGUID:(NSString *)typeGUID
{
    self.tagObject.clothingGUID = typeGUID;
    [self.navigationController popToViewController:self animated:YES];

    if(self.tagObject.clothingGUID.length && self.tagObject.brandGUID.length){
        self.navigationItem.leftBarButtonItem = self.doneButton;
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

    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    
    self.typeButton.hidden = self.brandButton.hidden = YES;
    [self.typeButton setTitle:@"" forState:UIControlStateNormal];
    [self.brandButton setTitle:@"" forState:UIControlStateNormal];
    [self.spinner startAnimating];

    self.typeButton.layer.borderWidth = self.brandButton.layer.borderWidth = 1;
    self.typeButton.layer.borderColor = self.brandButton.layer.borderColor = GREEN_COLOR.CGColor;
    
    dispatch_async(dispatch_queue_create("get tag details", NULL), ^{
        NSString *clothingName;
        NSString *brandName;

        BOOL complete = YES;
        if(self.tagObject.clothingGUID.length == 0){
            clothingName = STR_TAG_NO_CLOTHING_TYPE;
            complete = NO;
        }else{
            clothingName = [Clothing getNameForClothingWithGUID:self.tagObject.clothingGUID];
        }
        
        if(self.tagObject.brandGUID.length == 0){
            brandName = STR_TAG_NO_BRAND;
            complete = NO;
        }else{
            brandName = [Brand getNameForBrandWithGUID:self.tagObject.brandGUID];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.typeButton setTitle:clothingName forState:UIControlStateNormal];
            [self.brandButton setTitle:brandName forState:UIControlStateNormal];
            
            self.typeButton.hidden = self.brandButton.hidden = NO;
            [self.spinner stopAnimating];

            if(complete) self.navigationItem.leftBarButtonItem = self.doneButton;
        });
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:TYPE_SEGUE_NAME]){
        TagDetailsPickerViewController *vc = segue.destinationViewController;
        [vc setupTypeListUsingDelegate:self withDefaultGUID:self.tagObject.clothingGUID];
    }else if([segue.identifier isEqualToString:BRAND_SEGUE_NAME]){
        TagDetailsPickerViewController *vc = segue.destinationViewController;
        [vc setupBrandListUsingDelegate:self withDefaultGUID:self.tagObject.brandGUID];
    }
}

@end
