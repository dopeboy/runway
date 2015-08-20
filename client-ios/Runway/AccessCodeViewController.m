//
//  AccessCodeViewController.m
//  Runway
//
//  Created by Roberto Cordon on 8/12/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "AccessCodeViewController.h"

@interface AccessCodeViewController () <UITextFieldDelegate>
@property (nonatomic, weak) id<AccessCodeDelegate> delegate;
@property (nonatomic, weak) IBOutlet UILabel *labelMessage;
@property (nonatomic, weak) IBOutlet UITextField *textCode;
@property (nonatomic, strong) NSString *message;
@end

@implementation AccessCodeViewController

- (void)setupWithDelegate:(id<AccessCodeDelegate>)delegate
               andMessage:(NSString *)message
{
    self.message = message;
    self.delegate = delegate;
}

- (IBAction)submitButtonPressed
{
    [self.delegate accessCodeEntered:self.textCode.text];
}

- (IBAction)cancelButtonPressed
{
    [self.delegate accessCodeEntered:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self submitButtonPressed];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.labelMessage.text = self.message;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.textCode becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.textCode resignFirstResponder];

}

@end
