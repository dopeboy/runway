//
//  ImageListViewController.m
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "ImageListViewController.h"
#import "SWRevealViewController.h"

#import "SwiperViewController.h"
#import "Image.h"
#import "ImageListCell.h"
#import "FacebookPhoto.h"
#import "CenteredLabel.h"

#import "RunwayServices.h"
#import "CommonConstants.h"
#import "StringConstants.h"

#import "HelpView.h"

#define BROWSE_SEGUE_IDENTIFIER         @"browse segue"
#define FACEBOOK_SEGUE_IDENTIFIER       @"facebook segue"
#define ALERT_DELETE_CANCEL_INDEX       0
#define ALERT_DELETE_DELETE_INDEX       1

@interface ImageListViewController() <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic) BOOL viewHasAppeared;

@property (nonatomic, readonly) t_ImageListType listType;
@property (nonatomic, strong) NSMutableArray *imageList;
@property (nonatomic, strong) NSMutableArray *imageList2;
@property (nonatomic, strong) Image *imageToDelete;

@property (nonatomic, strong) UIButton *karmaButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *buttonSideMenu;
@end

@implementation ImageListViewController

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

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (void)setupListOfType:(t_ImageListType)listType
             usingTitle:(NSString *)title
{
    _listType = listType;
    self.navigationItem.title = title;
    [self karmaUpdated:nil];        //init karma label to 0. Make sure to call this before network calls that will update it via notif.

    [self.spinner startAnimating];
    dispatch_async(dispatch_queue_create("Get images", NULL), ^{
        if(listType == ImageListTypeMyImages){
            self.imageList = [[RunwayServices getMyImages] mutableCopy];
            [self.imageList insertObject:[NSNull null] atIndex:0];  //this will get interpreted as "new"
        }else if(listType == ImageListTypeFavorites){
            self.imageList = [[RunwayServices getFavoriteImages] mutableCopy];
        }else if(listType == ImageListTypeLeaderboard){
            NSDictionary *images = [RunwayServices getLeaderboardImages];
            self.imageList  = [images[@"friends"] mutableCopy];
            self.imageList2 = [images[@"others"] mutableCopy];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            [self.tableView reloadData];
        });
    });
}

- (void)refreshTable
{
    [self setupListOfType:self.listType usingTitle:self.navigationItem.title];
}

#pragma mark Helper Functions

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

#pragma mark Gesture Handlers

////////////////////////////////////////////////////////////////////////
//
// UITableViewDataSource Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource Implementation
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 1;
    if(self.imageList2.count) sections++;
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *imageList = (section == 0) ? self.imageList : self.imageList2;
    return imageList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if(self.imageList2.count){
        title = (section == 0) ? @"Friends" : @"Others";
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *imageCellIdentifier = @"imageCell";
    static NSString *newCellIdentifier   = @"newCell";
    UITableViewCell *cell;

    NSArray *imageList = (indexPath.section == 0) ? self.imageList : self.imageList2;
    
    if([imageList[indexPath.row] isKindOfClass:[NSNull class]]){
        cell = [tableView dequeueReusableCellWithIdentifier:newCellIdentifier];
    }else{
        ImageListCell *imageCell = [tableView dequeueReusableCellWithIdentifier:imageCellIdentifier forIndexPath:indexPath];
        
        Image *currentImage = imageList[indexPath.row];
        [imageCell setupWithImage:currentImage
                 andShowKarmaInfo:(self.listType == ImageListTypeMyImages)];
        
        cell = imageCell;
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle style;
    if(self.listType == ImageListTypeMyImages){
        style = ([self.imageList[indexPath.row] isKindOfClass:[NSNull class]]) ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
    }else{
        style = UITableViewCellEditingStyleNone;
    }
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){
        self.imageToDelete = self.imageList[indexPath.row];

        [[[UIAlertView alloc] initWithTitle:STR_IMAGE_DELETE_CONFIRM_TITLE
                                    message:STR_IMAGE_DELETE_CONFIRM_MESSAGE
                                   delegate:self
                          cancelButtonTitle:STR_IMAGE_DELETE_CONFIRM_CANCEL
                          otherButtonTitles:STR_IMAGE_DELETE_CONFIRM_DELETE, nil] show];
    }
}

////////////////////////////////////////////////////////////////////////
//
// UITableViewDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewDelegate Implementation
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.listType != ImageListTypeLeaderboard){
        NSArray *imageList = (indexPath.section == 0) ? self.imageList : self.imageList2;
        
        if([imageList[indexPath.row] isKindOfClass:[NSNull class]]){
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Image Source"
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:@"Facebook", @"Camera", @"Camera Roll", nil];
            [actionSheet showInView:self.view];
        }else{
            Image *currentImage = imageList[indexPath.row];
            [self performSegueWithIdentifier:BROWSE_SEGUE_IDENTIFIER sender:currentImage];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

////////////////////////////////////////////////////////////////////////
//
// UIActionSheetDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark UIActionSheetDelegate Implementation
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0){
        //facebook
        [self performSegueWithIdentifier:FACEBOOK_SEGUE_IDENTIFIER sender:nil];
    }else{
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;

        if((buttonIndex == 1) && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }else if((buttonIndex == 2) && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }else{
            imagePicker = nil;
        }
        
        if(imagePicker){
            [self presentViewController:imagePicker animated:YES completion:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"Could not access photos"
                                        message:@"Make sure you have granted permissions."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];

        }
    }
}

////////////////////////////////////////////////////////////////////////
//
// UIImagePickerControllerDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark UIImagePickerControllerDelegate Implementation
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //get image and scale it
    UIImage *fullImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CGSize newSize;
    newSize.width = SWIPER_VIEW_WIDTH_UNSCALED;
    newSize.height = SWIPER_VIEW_WIDTH_UNSCALED * (fullImage.size.height / fullImage.size.width);
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    [fullImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    FacebookPhoto *fbPhoto = [[FacebookPhoto alloc] initWithImageFromDevice:newImage];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:BROWSE_SEGUE_IDENTIFIER sender:fbPhoto];
    }];
}

////////////////////////////////////////////////////////////////////////
//
// Notification Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark Notification Handlers
- (void)karmaUpdated:(NSNotification *)notification
{
    NSInteger karma = notification ? [notification.userInfo[notification.name] integerValue] : [RunwayServices readKarma];
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
    
    NSString *titleText = self.navigationItem.title;
    UIFont* titleFont = UINavigationBar.appearance.titleTextAttributes[NSFontAttributeName];
    CGFloat titleWidth = [titleText sizeWithAttributes:@{NSFontAttributeName: titleFont}].width;
    
    CenteredLabel *navLabel = [[CenteredLabel alloc] initWithFrame:CGRectMake(0, 0, titleWidth, 20)];
    navLabel.backgroundColor = UINavigationBar.appearance.titleTextAttributes[NSBackgroundColorAttributeName];
    navLabel.textColor = UINavigationBar.appearance.titleTextAttributes[NSForegroundColorAttributeName];
    navLabel.font = titleFont;
    navLabel.textAlignment = NSTextAlignmentCenter;
    navLabel.text = titleText;
    self.navigationItem.titleView = navLabel;
    
//    [HelpView showIfApplicableInsideOfView:self.view usingImageNamed:@"Logo.png" andHelpViewId:1];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:BROWSE_SEGUE_IDENTIFIER]){
        SwiperViewController *vc = segue.destinationViewController;
        
        if([sender isKindOfClass:[FacebookPhoto class]]){
            [vc setupWithFacebookPhoto:sender];
        }else{
            BOOL allowEdit = (self.listType == ImageListTypeMyImages);

            [vc setupWithImage:sender
                    allowSwipe:NO
                     allowEdit:allowEdit
                   allowVoting:NO];

            [vc addBackButton];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == ALERT_DELETE_CANCEL_INDEX){
        //do nothing
    }else if(buttonIndex == ALERT_DELETE_DELETE_INDEX){
        NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.imageList indexOfObject:self.imageToDelete] inSection:0];

        [self.imageList removeObject:self.imageToDelete];
        [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        dispatch_async(dispatch_queue_create("delete image", NULL), ^{
            [self.imageToDelete deleteSelf];
        });
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
