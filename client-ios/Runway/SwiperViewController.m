//
//  SwiperViewController.m
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "SwiperViewController.h"
#import "SWRevealViewController.h"

#import "RunwayServices.h"
#import "SwiperView.h"
#import "Image.h"
#import "Tag.h"
#import "TagView.h"

#import "EditTagDetailsViewController.h"
#import "ImageListViewController.h"

#import "CommonConstants.h"

#define EDIT_SEGUE_NAME     @"edit segue"

@interface SwiperViewController() <SwiperDelegate, EditTagDetailsDelegate>
@property (nonatomic) BOOL hasBeenSetup;
@property (nonatomic) BOOL viewWillAppearCalled;

@property (nonatomic) BOOL saveCurtainVisible;
@property (nonatomic, strong) UIView *saveCurtain;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) Image *image;
@property (nonatomic) BOOL allowSwipe;
@property (nonatomic) BOOL allowEdit;
@property (nonatomic) BOOL allowVoting;
@property (nonatomic) BOOL startInEditMode;

@property (nonatomic, strong) SwiperView *currentSwipe;
@property (nonatomic, strong) SwiperView *nextSwipe;

@property (nonatomic, strong) UIBarButtonItem *leftButtonItem;
@property (nonatomic, strong) UIButton *karmaButton;
@property (nonatomic, strong) IBOutlet UIButton *swipeButton;
@property (nonatomic, strong) IBOutlet UITableView *tableForReasons;
@end

@implementation SwiperViewController

////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
#pragma mark - Getters/Setters
- (UIButton *)karmaButton
{
    if(!_karmaButton){
        UIButton *karmaButton = [UIButton buttonWithType:UIButtonTypeCustom];
        karmaButton.frame = CGRectMake(0, 0, 100, 44);
        karmaButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        karmaButton.contentEdgeInsets = UIEdgeInsetsZero;
        karmaButton.titleLabel.font = FONT(14);
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:karmaButton];
        _karmaButton = karmaButton;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(karmaUpdated:) name:NOTIFICATION_KARMA_UPDATED object:nil];
    }
    return _karmaButton;
}

- (void)setAllowSwipe:(BOOL)allowSwipe
{
    _allowSwipe = allowSwipe;
    self.swipeButton.hidden = !allowSwipe;
}

- (void)setSaveCurtainVisible:(BOOL)saveCurtainVisible
{
    _saveCurtainVisible = saveCurtainVisible;
    if(saveCurtainVisible){
        if(!self.saveCurtain){
            self.saveCurtain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            self.saveCurtain.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
            
            self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            self.spinner.center = self.saveCurtain.center;
            self.spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            [self.spinner startAnimating];
            [self.saveCurtain addSubview:self.spinner];
        }
        
        self.saveCurtain.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        self.spinner.center = self.saveCurtain.center;
        [self.view addSubview:self.saveCurtain];
    }else{
        [self.saveCurtain removeFromSuperview];
    }
}

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupWithImage:(Image *)image
            allowSwipe:(BOOL)allowSwipe
             allowEdit:(BOOL)allowEdit
           allowVoting:(BOOL)allowVoting
{
    self.hasBeenSetup = YES;

    self.image = image;
    self.allowSwipe = allowSwipe;
    self.allowEdit = allowEdit;
    self.allowVoting = allowVoting;
}

- (void)setupWithFacebookPhoto:(FacebookPhoto *)photo
{
    self.hasBeenSetup = YES;

    self.image = [[Image alloc] initWithGUID:nil
                                       title:@"NEW"
                               facebookPhoto:photo
                                 andTagArray:nil
                                      iOwnIt:YES];
    
    self.allowSwipe = NO;
    self.allowEdit = YES;
    self.allowVoting = NO;
    self.startInEditMode = YES;
}

- (void)addBackButton
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(popVC)];
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (void)loadRandomImageForCurrent:(BOOL)current
{
    dispatch_async(dispatch_queue_create("next image getter", NULL), ^{
        Image *nextImage = [RunwayServices getNextImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(current){
                self.currentSwipe.image = nextImage;
            }else{
                self.nextSwipe.image = nextImage;
            }
        });
    });
}

- (void)setupNextSwiper
{
    self.nextSwipe = [[SwiperView alloc] initWithNoImageAndAllowSwipe:self.allowSwipe
                                                            allowEdit:self.allowEdit
                                                          allowVoting:self.allowVoting
                                                              toFitIn:self.view.frame.size
                                                        usingDelegate:self
                                                             andTable:self.tableForReasons];
    self.nextSwipe.blur = 1;
    
    [self loadRandomImageForCurrent:NO];
    [self.view insertSubview:self.nextSwipe belowSubview:self.currentSwipe];
    
    self.nextSwipe.gestureEnabled = NO;
}

- (void)popVC
{
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [self.navigationController popViewControllerAnimated:YES];
}

////////////////////////////////////////////////////////////////////////
//
// IBAction Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark - IBAction Handlers
- (IBAction)showSideMenu:(id)sender
{
    [self.revealViewController revealToggle:sender];
}

- (IBAction)nextButtonPressed:(id)sender
{
    self.swipeButton.enabled = NO;
    [self.currentSwipe forceSwipeOut];
}

- (void)editButtonPressed:(id)sender
{
    self.currentSwipe.editing = YES;
    
    self.leftButtonItem = self.navigationItem.leftBarButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditButtonPressed:)];
}

- (void)doneEditButtonPressed:(id)sender
{
    self.currentSwipe.editing = NO;

    self.saveCurtainVisible = YES;

    self.navigationItem.leftBarButtonItem = self.leftButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
   
    
    BOOL needToPop = (!self.image.GUID);    //if no GUID, then it's new, and we need to pop
    dispatch_async(dispatch_queue_create("get tag details", NULL), ^{
        [self.image saveEditChanges];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.saveCurtainVisible = NO;
            
            if(needToPop){
                if([self.navigationController.viewControllers[0] isKindOfClass:[ImageListViewController class]]){
                    ImageListViewController *vc = (ImageListViewController *)self.navigationController.viewControllers[0];
                    [vc refreshTable];

                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
        });
    });

}

- (void)addButtonPressed:(id)sender
{
    Tag *tag = [[Tag alloc] initWithGUID:nil
                        forParentImageID:self.image.GUID
                       usingClothingGUID:nil
                            andBrandGUID:nil
                                position:CGPointMake(self.currentSwipe.frame.size.width / 2, self.currentSwipe.frame.size.height / 2)
                         downvoteReasons:nil
                                  myVote:VoteUp
                                  iOwnIt:YES];
    [self.image addTag:tag];
    
    TagView *tagView = [[TagView alloc] initWithTag:tag
                                   usingScaleFactor:self.currentSwipe.scaleFactor
                                            toFitIn:self.currentSwipe.frame.size
                                          allowEdit:YES
                                        allowVoting:NO
                                           delegate:self.currentSwipe];
    tagView.editing = YES;
    tagView.selected = YES;
    [self.currentSwipe addSubview:tagView];
    
    [self editPropertiesForTag:tag];
}

#pragma mark Gesture Handlers

////////////////////////////////////////////////////////////////////////
//
// SwiperDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - SwiperDelegate Implementation
- (void)swipedOutSwiperView:(SwiperView *)swiperView
{
    [self.currentSwipe.image saveVotes];
    
    self.currentSwipe = self.nextSwipe;
    self.currentSwipe.gestureEnabled = YES;
    self.currentSwipe.blur = 0;
    
    [self setupNextSwiper];
    
    self.swipeButton.enabled = YES;
}

- (void)editPropertiesForTag:(Tag *)tag
{
    [self performSegueWithIdentifier:EDIT_SEGUE_NAME sender:tag];
}

- (void)swiperView:(SwiperView *)swiperView updatedSwipedPercent:(CGFloat)percent;
{
    self.nextSwipe.blur = fmin(fmax(percent, 0.0), 1.0);
}

////////////////////////////////////////////////////////////////////////
//
// EditTagDetailsDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark EditTagDetailsDelegate Implementation
- (void)cancelledEditingDetailsForTag:(Tag *)tag
{
    [self.image deleteTag:tag];
    
    [self.currentSwipe removeTagViewForTag:tag];
}

////////////////////////////////////////////////////////////////////////
//
// Notification Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark Notification Handlers
- (void)karmaUpdated:(NSNotification *)notification
{
    NSInteger karma = [notification.userInfo[notification.name] integerValue];
    [self.karmaButton setTitle:[NSString stringWithFormat:@"%zd pts", karma] forState:UIControlStateNormal];
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewController Overrides
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewController Overrides
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!self.viewWillAppearCalled){
        self.viewWillAppearCalled = YES;
        
        self.view.backgroundColor = [UIColor redColor];
        [self karmaUpdated:nil];        //init karma label to 0. Make sure to call this before network calls that will update it via notif.

        //init view if necessary
        if(!self.hasBeenSetup){
            //if we're here, it's because setup hasn't been called, which means we're not here throuh a segue, which means it's the SWReveal which loaded us.
            //We must call setup ourselves, with the same values the side menu would send.
            [self setupWithImage:nil
                      allowSwipe:YES
                       allowEdit:NO
                     allowVoting:YES];
            
        }
        
        //init current swipe view
        if(self.image){
            self.currentSwipe = [[SwiperView alloc] initWithImage:self.image
                                                       allowSwipe:self.allowSwipe
                                                        allowEdit:self.allowEdit
                                                      allowVoting:self.allowVoting
                                                          toFitIn:self.view.frame.size
                                                    usingDelegate:self
                                                         andTable:self.tableForReasons];
        }else{
            self.currentSwipe = [[SwiperView alloc] initWithNoImageAndAllowSwipe:self.allowSwipe
                                                                       allowEdit:self.allowEdit
                                                                     allowVoting:self.allowVoting
                                                                         toFitIn:self.view.frame.size
                                                                   usingDelegate:self
                                                                        andTable:self.tableForReasons];
            [self loadRandomImageForCurrent:YES];
        }
        [self.view addSubview:self.currentSwipe];
        
        //init next swipe view
        if(self.allowSwipe){
            [self setupNextSwiper];
        }
        
        //setup swipe button
        self.swipeButton.hidden = !self.allowSwipe;
        
        //setup edit button
        if(self.allowEdit){
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
            
            if(self.startInEditMode){
                [self editButtonPressed:nil];
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:EDIT_SEGUE_NAME]){
        UINavigationController *navVC = segue.destinationViewController;
        EditTagDetailsViewController *vc = (EditTagDetailsViewController *)navVC.topViewController;
        [vc setupForTag:sender
           withDelegate:self];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
