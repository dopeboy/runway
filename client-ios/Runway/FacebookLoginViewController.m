//
//  FacebookLoginViewController.m
//  Runway
//
//  Created by Roberto Cordon on 5/15/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "FacebookLoginViewController.h"
#import "RunwayServices.h"
#import "AccessCodeViewController.h"

#import "CommonConstants.h"
#import "StringConstants.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#define LOGIN_SEGUE_NAME            @"perform login"
#define ACCESS_CODE_SEGUE_NAME      @"modal access code"

#define DEFAULTS_CODE               @"defaults access code"

@interface FacebookLoginViewController () <FBSDKLoginButtonDelegate, AccessCodeDelegate>

@property (nonatomic, weak) IBOutlet FBSDKLoginButton *loginButton;
@property (nonatomic, weak) IBOutlet UIButton *proceedButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic) BOOL hasAppeared;
@property (nonatomic) BOOL didAppearCalled;
@property (nonatomic, strong) NSString *needsToDisplayCodeScreenMessage;
@end

@implementation FacebookLoginViewController

#pragma mark - Getters/Setters
#pragma mark Public Functions

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (void)updateProceedButton
{
    FBSDKProfile *profile = [FBSDKProfile currentProfile];
    if([FBSDKAccessToken currentAccessToken] && profile){
        self.proceedButton.hidden = NO;
        [self.proceedButton setTitle:[NSString stringWithFormat:STR_FACEBOOK_PROCEED_BUTTON_FMT, profile.name] forState:UIControlStateNormal];
    }else{
        self.proceedButton.hidden = YES;
    }
}

- (void)attemptToEnter
{
    FBSDKProfile *profile = [FBSDKProfile currentProfile];
    if([FBSDKAccessToken currentAccessToken] && profile){
        [self.spinner startAnimating];
        
        [RunwayServices loginOnSeparateThreadWithCompletionBlock:^(NSString *errorMessage){
            if(!errorMessage){
                [self performSegueWithIdentifier:LOGIN_SEGUE_NAME sender:self];
                [self updateProceedButton];
            }else if([errorMessage isEqualToString:@"code_required"] || [errorMessage isEqualToString:@"code_incorrect"]){
                NSString *messageForCode = [errorMessage isEqualToString:@"code_required"] ? @"Code required." : @"Incorrect code.\nPlease try again.";

                if(self.didAppearCalled){
                    [self performSegueWithIdentifier:ACCESS_CODE_SEGUE_NAME sender:messageForCode];
                }else{
                    self.needsToDisplayCodeScreenMessage = messageForCode;
                }
            }else{
                [[[UIAlertView alloc] initWithTitle:@"Could not log into Runway"
                                            message:@"Facebook logged in successfully, but there was a problem logging into runway. Please try again later."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                [self updateProceedButton];
            }
            [self.spinner stopAnimating];

        }];
    }
}

////////////////////////////////////////////////////////////////////////
//
// IBAction Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark - IBAction Handlers
- (IBAction)proceedButtonPressed:(id)sender
{
    [self attemptToEnter];
}

#pragma mark Gesture Handlers

////////////////////////////////////////////////////////////////////////
//
// Notification Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark Notification Handlers
- (void)profileChangeNotificationHandler:(NSNotification *)notfication
{
    [self attemptToEnter];
}

- (void)tokenChangeNotificationHandler:(NSNotification *)notfication
{
    [self attemptToEnter];
}

////////////////////////////////////////////////////////////////////////
//
// FBSDKLoginButtonDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - FBSDKLoginButtonDelegate Implementation
- (void)loginButton:(FBSDKLoginButton *)loginButton
didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
              error:(NSError *)error
{
    if(error){
        [[[UIAlertView alloc] initWithTitle:error.userInfo[FBSDKErrorLocalizedTitleKey] ?: @"Oops"
                                    message:error.userInfo[FBSDKErrorLocalizedDescriptionKey] ?: @"There was a problem logging in. Please try again later."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }else{
        [self attemptToEnter];
    }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
    [self updateProceedButton];
}

////////////////////////////////////////////////////////////////////////
//
// AccessCodeDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - AccessCodeDelegate Implementation
- (void)accessCodeEntered:(NSString *)code
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self updateProceedButton];
        if(code){
            [[NSUserDefaults standardUserDefaults] setObject:code forKey:DEFAULTS_CODE];
            [self attemptToEnter];
        }
    }];
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
    
    if(!self.hasAppeared){
        self.hasAppeared = YES;
        
        self.proceedButton.layer.borderWidth = 0.5;
        self.proceedButton.layer.borderColor = GREEN_COLOR.CGColor;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileChangeNotificationHandler:) name:FBSDKProfileDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenChangeNotificationHandler:) name:FBSDKAccessTokenDidChangeNotification object:nil];
        
        self.loginButton.readPermissions = @[
                                             @"public_profile",
                                             @"user_photos",
                                             @"user_birthday",
                                             @"user_friends",
                                             @"email",
                                             ];
        self.loginButton.delegate = self;
        self.loginButton.backgroundColor = [UIColor blackColor];
        
        [self attemptToEnter];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(!self.didAppearCalled){
        self.didAppearCalled = YES;
        
        if(self.needsToDisplayCodeScreenMessage){
            [self performSegueWithIdentifier:ACCESS_CODE_SEGUE_NAME sender:self.needsToDisplayCodeScreenMessage];
            self.needsToDisplayCodeScreenMessage = nil;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:ACCESS_CODE_SEGUE_NAME]){
        AccessCodeViewController *vc = segue.destinationViewController;
        [vc setupWithDelegate:self andMessage:sender];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
