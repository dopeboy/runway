//
//  SwiperView.m
//  Runway
//
//  Created by Roberto Cordon on 5/25/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "SwiperView.h"
#import "Image.h"
#import "Tag.h"
#import "DownvoteReasonsView.h"

#import "Clothing.h"
#import "Brand.h"

#import "UIImage+ImageEffects.h"

#import "CommonConstants.h"

#define IMAGE_WIDTH                 SWIPER_VIEW_WIDTH_UNSCALED
#define IMAGE_HEIGHT                400.0
#define SWIPE_MINIMUM_DISTANCE      100.0
#define SWIPE_MAXIMUM_DURATION        0.5

@interface SwiperView()
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UIImageView *blurView;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;

@property (nonatomic) BOOL allowSwipe;
@property (nonatomic) BOOL allowEdit;
@property (nonatomic) BOOL allowVoting;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic) CGPoint gestureStartCenterPoint;

@property (nonatomic, weak) id<SwiperDelegate> delegate;
@property (nonatomic, weak) UITableView *tableForReasons;
@end

@implementation SwiperView

////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
#pragma mark - Getters/Setters
- (void)setImage:(Image *)image
{
    _image = image;
    
    if(image){
        if(image.fullImageAvailable){
            [self setupImage:image.fullImage];
        }else{
            [self setupSpinnerAndLoadImageIfApplicable];
        }
    }
}

- (BOOL)gestureEnabled
{
    return self.panGesture.enabled;
}

- (void)setGestureEnabled:(BOOL)gestureEnabled
{
    self.panGesture.enabled = gestureEnabled;
}

- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    for(UIView *v in self.subviews){
        if([v isKindOfClass:[TagView class]]){
            TagView *t = (TagView *)v;
            t.editing = editing;
        }
    }
}

- (void)setBlur:(CGFloat)blur
{
    if(!self.blurView && self.imageView.image){
        UIImageView *blurView = [[UIImageView alloc] initWithFrame:self.imageView.frame];
        blurView.image = [self.imageView.image applyLightEffect];
        [self insertSubview:blurView aboveSubview:self.imageView];
        
        self.blurView = blurView;
    }
    self.blurView.alpha = MIN(1, (blur * blur * blur) * 3);    //cube it and triple it, since 0 < x < 1, it will blur slowly at first and quickly later
}

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (SwiperView *)initWithImage:(Image *)image
                   allowSwipe:(BOOL)allowSwipe
                    allowEdit:(BOOL)allowEdit
                  allowVoting:(BOOL)allowVoting
                      toFitIn:(CGSize)size
                usingDelegate:(id<SwiperDelegate>)delegate
                     andTable:(UITableView *)tableForReasons
{
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    if(self = [super initWithFrame:frame]){
        //property setup
        self.scaleFactor = CGPointMake(frame.size.width / IMAGE_WIDTH, frame.size.width / IMAGE_WIDTH);
        self.allowSwipe = allowSwipe;
        self.allowEdit = allowEdit;
        self.allowVoting = allowVoting;
        self.image = image;                 //image must be set after the "allow" flags.
        self.delegate = delegate;
        self.tableForReasons = tableForReasons;

        //setup gesture recognizer
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureHandler:)];
        [self addGestureRecognizer:self.panGesture];
        self.gestureEnabled = self.allowSwipe;
        
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (SwiperView *)initWithNoImageAndAllowSwipe:(BOOL)allowSwipe
                                   allowEdit:(BOOL)allowEdit
                                 allowVoting:(BOOL)allowVoting
                                     toFitIn:(CGSize)size
                               usingDelegate:(id<SwiperDelegate>)delegate
                                    andTable:(UITableView *)tableForReasons
{
    if(self = [self initWithImage:nil allowSwipe:allowSwipe allowEdit:allowEdit allowVoting:allowVoting toFitIn:size usingDelegate:delegate andTable:tableForReasons]){
        //nothing else needs to be done
    }
    return self;
}

- (void)forceSwipeOut
{
    CGPoint destinationPoint = self.center;
    destinationPoint.x-= self.frame.size.width;
    
    [self swipeOutToPoint:destinationPoint withAnimationDuration:SWIPE_MAXIMUM_DURATION];
}

- (void)removeTagViewForTag:(Tag *)tag
{
    for(UIView *v in self.subviews){
        if([v isKindOfClass:[TagView class]]){
            TagView *t = (TagView *)v;
            if([t isTagViewForTag:tag]){
                [t removeFromSuperview];
                break;
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (void)setupImage:(UIImage *)imageToSetup
{
    //take care of spinner
    [self.spinner removeFromSuperview];
    
    //take care of image
    UIImageView *imageView = [[UIImageView alloc] initWithImage:imageToSetup];
    imageView.frame = CGRectMake(0, 0, IMAGE_WIDTH * self.scaleFactor.x, IMAGE_HEIGHT * self.scaleFactor.y);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    imageView.clipsToBounds = YES;
    [self addSubview:imageView];
    
    self.imageView = imageView;
    self.imageView.backgroundColor = [UIColor blackColor];

    //take care of tag views
    for(Tag* tag in self.image.tags){
        TagView *tagView = [[TagView alloc] initWithTag:tag
                                       usingScaleFactor:self.scaleFactor
                                                toFitIn:self.frame.size
                                              allowEdit:self.allowEdit
                                            allowVoting:self.allowVoting
                                               delegate:self];
        
        [self addSubview:tagView];
    }
}

- (void)setupSpinnerAndLoadImageIfApplicable
{
    //setup spinner
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [spinner startAnimating];
    [self addSubview:spinner];
    
    self.spinner = spinner;
    
    //load image
    if(self.image){
        dispatch_async(dispatch_queue_create("image getter", NULL), ^{
            UIImage *tmpImg = self.image.fullImage;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupImage:tmpImg];
            });
        });
    }

}

- (void)swipeOutToPoint:(CGPoint)destinationPoint
  withAnimationDuration:(NSTimeInterval)animationDuration
{
    if(animationDuration > SWIPE_MAXIMUM_DURATION) animationDuration = SWIPE_MAXIMUM_DURATION;
    
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.center = destinationPoint;
                         self.alpha = 0.5;
                         [self.delegate swiperView:self updatedSwipedPercent:0];
                     }
                     completion:^(BOOL finished){
                         [self removeFromSuperview];
                         [self.delegate swipedOutSwiperView:self];
                     }];
    
}

#pragma mark - IBAction Handlers

////////////////////////////////////////////////////////////////////////
//
// Gesture Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark Gesture Handlers
- (void)swipeGestureHandler:(UIPanGestureRecognizer *)gesture
{
    UIGestureRecognizerState state = gesture.state;
    CGPoint translation = [gesture translationInView:self];

    if(state == UIGestureRecognizerStateBegan){
        self.gestureStartCenterPoint = self.center;
    }else if(state == UIGestureRecognizerStateChanged){
        if((self.frame.origin.x + self.frame.size.width + translation.x) <= self.superview.frame.size.width){
            CGPoint selfCenter = self.center;
            selfCenter.x+= translation.x;
            self.center = selfCenter;
        }

        [gesture setTranslation:CGPointZero inView:self];
    }else if(state == UIGestureRecognizerStateEnded){
        //temporarily disable
        gesture.enabled = NO;
        
        //calculate distance to see if outside of radius.
        CGFloat deltaX = fabs(self.center.x - self.gestureStartCenterPoint.x);
        CGFloat deltaY = fabs(self.center.y - self.gestureStartCenterPoint.y);
        
        if((deltaX < SWIPE_MINIMUM_DISTANCE) && (deltaY < SWIPE_MINIMUM_DISTANCE)){
            [UIView animateWithDuration:ANIMATION_DURATION
                             animations:^{
                                 self.center = self.gestureStartCenterPoint;
                             }
                             completion:^(BOOL finished){
                                 gesture.enabled = YES;
                             }];
        }else{
            //determine the final position for the view.
            BOOL left = (self.center.x < self.gestureStartCenterPoint.x);
            BOOL up   = (self.center.y < self.gestureStartCenterPoint.y);
            
            CGPoint destinationPoint = CGPointMake(self.gestureStartCenterPoint.x, self.center.y);
            if(left){
                destinationPoint.x-= self.frame.size.width;
            }else{
                destinationPoint.x+= self.frame.size.width;
            }
            CGFloat percentOffsetX = fabs(deltaX / (destinationPoint.x - self.gestureStartCenterPoint.x));
            if(up){
                destinationPoint.y-= (deltaY / percentOffsetX);
            }else{
                destinationPoint.y+= (deltaY / percentOffsetX);
            }
            
            //determine the duration of the animation
            CGPoint velocityComponents = [gesture velocityInView:self];
            CGFloat velocity = sqrt((velocityComponents.x * velocityComponents.x) + (velocityComponents.y * velocityComponents.y));

            CGFloat distanceToTravelX = self.center.x - destinationPoint.x;
            CGFloat distanceToTravelY = self.center.y - destinationPoint.y;
            CGFloat distanceToTravel = sqrt((distanceToTravelX * distanceToTravelX) + (distanceToTravelY * distanceToTravelY));

            NSTimeInterval time = distanceToTravel / velocity;

            [self swipeOutToPoint:destinationPoint withAnimationDuration:time];
        }
    }
    
    CGFloat swipeMagic = ((self.center.x + self.superview.center.x) / self.superview.frame.size.width);
    self.alpha = (swipeMagic / 2) + 0.5;
    [self.delegate swiperView:self updatedSwipedPercent:swipeMagic];
}

////////////////////////////////////////////////////////////////////////
//
// TagDelegate Implementation
//
////////////////////////////////////////////////////////////////////////
#pragma mark - TagDelegate Implementation
- (void)displayDownvoteReasonDialogForTag:(Tag *)tag withView:(TagView *)tagView
{
    [DownvoteReasonsView createInstanceInSuperview:self
                                            forTag:tag
                                           andView:tagView
                                         withTable:self.tableForReasons
                                          andTitle:@"Please explain why you down-voted:"
                                  showingStatsOnly:NO];
}

- (void)displayDownvoteReasonStatsDialogForTag:(Tag *)tag withView:(TagView *)tagView
{
    NSString *title = [NSString stringWithFormat:@"%@ from %@", [Clothing getNameForClothingWithGUID:tag.clothingGUID], [Brand getNameForBrandWithGUID:tag.brandGUID]];

    [DownvoteReasonsView createInstanceInSuperview:self
                                            forTag:tag
                                           andView:tagView
                                         withTable:self.tableForReasons
                                          andTitle:title
                                  showingStatsOnly:YES];
}

- (void)selectedTagView:(TagView *)tagView
{
    for(UIView *v in self.subviews){
        if((v != tagView) && [v isKindOfClass:[TagView class]]){
            TagView *t = (TagView *)v;
            t.selected = NO;
        }
    }
}

- (void)editPropertiesForTag:(Tag *)tag
{
    [self.delegate editPropertiesForTag:tag];
}

- (void)deleteTag:(Tag *)tag andRemoveTagView:(TagView *)tagView
{
    [self.image deleteTag:tag];
    [tagView removeFromSuperview];
}

#pragma mark - UIView Overrides

@end
