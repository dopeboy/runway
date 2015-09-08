//
//  TagView.m
//  Runway
//
//  Created by Roberto Cordon on 5/26/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "TagView.h"
#import "Tag.h"
#import "TagViewPopup.h"

#import "Clothing.h"
#import "Brand.h"
#import "DownvoteReason.h"

#import "CommonConstants.h"
#import "StringConstants.h"

#define CIRCLE_RADIUS                       12
#define TEXT_HEIGHT                         32

#define TAG_VIEW_HEIGHT                     (CIRCLE_RADIUS + TEXT_HEIGHT)

#define LINE_OFFSET                         CIRCLE_RADIUS
#define LINE_WIDTH                          1
#define MIN_LINE_LENGTH                     15

#define DIALOG_WIDTH_FOR_KARMA              70
#define KARMA_PADDING                       7
#define KARMA_MINI_PAD                      2
#define MINI_PAD                            4

#define KARMA_UP_MAGIC_Y_PAD                1
#define KARMA_DOWN_MAGIC_Y_PAD              2

#define COLOR_SELECTED                      [UIColor whiteColor]
#define COLOR_NOVOTE                        [UIColor whiteColor]
#define COLOR_UPVOTE                        GREEN_COLOR
#define COLOR_DOWNVOTE                      PINK_COLOR

#define ALERT_DELETE_CANCEL_INDEX           0
#define ALERT_DELETE_DELETE_INDEX           1

typedef enum {
    TagViewDialogTypeNone,
    TagViewDialogTypeDetails,
    TagViewDialogTypeDownReasons,
    TagViewDialogTypeKarma,
}t_TagViewDialogType;

@interface TagView()
@property (nonatomic, weak) id<TagDelegate> delegate;
@property (nonatomic, weak) TagViewPopup *popup;
@property (nonatomic, strong) Tag *tagObject;

@property (nonatomic) BOOL allowEdit;
@property (nonatomic) BOOL allowVoting;
@property (nonatomic) CGPoint scaleFactor;
@property (nonatomic) BOOL dragging;
@property (nonatomic) BOOL pulsating;

@property (nonatomic, weak) UITapGestureRecognizer *tapGesture;
@property (nonatomic, weak) UILongPressGestureRecognizer *holdGesture;
@end

@implementation TagView

////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
#pragma mark - Getters/Setters
- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    self.selected = NO;
    
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    if(selected){
        [self.delegate selectedTagView:self];
    }
    
    [self setNeedsDisplay];
}

- (t_Vote)voteState
{
    return self.tagObject.myVote;
}

- (void)setReveal:(BOOL)reveal
{
    _reveal = reveal;
    
    self.allowVoting = !reveal;
    self.tapGesture.enabled = !reveal;
}

- (void)setPulsating:(BOOL)pulsating
{
    _pulsating = pulsating;
    
    if(pulsating){
        [UIView animateWithDuration:0.7
                              delay:0
                            options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             //manish
                             self.alpha = 0.5;
                         }
                         completion:nil];
    }
}

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (TagView *)initWithTag:(Tag *)tag
        usingScaleFactor:(CGPoint)scaleFactor
                 toFitIn:(CGSize)size
               allowEdit:(BOOL)allowEdit
             allowVoting:(BOOL)allowVoting
                delegate:(id<TagDelegate>)delegate
{
    tag.scaleFactor = scaleFactor;
    if(self = [super initWithFrame:[self frameForViewBasedOnTag:tag toFitIn:size]]){
        self.backgroundColor = [UIColor clearColor];
        self.tagObject = tag;
        self.delegate = delegate;
        self.allowEdit = allowEdit;
        self.allowVoting = allowVoting;
        self.scaleFactor = scaleFactor;

        if(allowEdit){
            [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
        }
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGesture];
        self.tapGesture = tapGesture;
        
        UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [self addGestureRecognizer:holdGesture];
        self.holdGesture = holdGesture;
        self.holdGesture.enabled = NO;
        self.holdGesture.minimumPressDuration = 0.2;
    }
    return self;
}

- (void)setDownvoteReasonForTag:(DownvoteReason *)downvoteReason            //nil means cancelled
{
    if(downvoteReason){
        [self.tagObject setAndSaveDownvoteWithReason:downvoteReason];
    }else{
        self.tagObject.myVote = VoteNone;                                   //set it here so that when we redraw it draws properly. Setting to "up" since that was the last thing we told the server.
        [self.delegate changedVoteState];
    }
    
    [self setNeedsDisplay];
}

- (BOOL)isTagViewForTag:(Tag *)tag
{
    return (tag == self.tagObject);
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
- (CGRect)frameForViewBasedOnTag:(Tag *)tag
                         toFitIn:(CGSize)size
{
    CGFloat midScreen = (size.width / 2);
    BOOL tagOnLeftSideOfScreen = (tag.adjustedPosition.x < midScreen);
    CGFloat width = tagOnLeftSideOfScreen ? (tag.adjustedPosition.x) : (size.width - tag.adjustedPosition.x);
    CGFloat x = tagOnLeftSideOfScreen ? 0 : tag.adjustedPosition.x;
    if(width < TAG_VIEW_HEIGHT){
        width = TAG_VIEW_HEIGHT;
        if(!tagOnLeftSideOfScreen) x = size.width - TAG_VIEW_HEIGHT;
    }
    
    return CGRectMake(x,
                      tag.adjustedPosition.y - LINE_OFFSET,
                      width,
                      TAG_VIEW_HEIGHT);
}

- (void)showContextMenu
{
    [self becomeFirstResponder];
    
    UIMenuController *ctxMenu = [UIMenuController sharedMenuController];
    ctxMenu.arrowDirection = UIMenuControllerArrowDefault;
    ctxMenu.menuItems = @[
                          [[UIMenuItem alloc] initWithTitle:STR_TAG_EDIT_PROPERTIES action:@selector(editProperties)],
                          [[UIMenuItem alloc] initWithTitle:STR_TAG_DELETE          action:@selector(deleteSelf)],
                          ];
    
    
    [ctxMenu setTargetRect:self.frame inView:self.superview];
    [ctxMenu setMenuVisible:YES animated:YES];
}

- (UIFont *)fontForDialog
{
    return FONT(14);
}

- (CGSize)sizeRequiredForDialog
{
    CGSize size;
    
    t_TagViewDialogType dialogType = [self getDialogType];

    if((dialogType == TagViewDialogTypeDetails) || (dialogType == TagViewDialogTypeDownReasons)){
        size = [[self stringForDialog] sizeWithAttributes:@{NSFontAttributeName:[self fontForDialog]}];
        if(size.width < (CIRCLE_RADIUS + CIRCLE_RADIUS)) size.width = (CIRCLE_RADIUS + CIRCLE_RADIUS);
    }else if(dialogType == TagViewDialogTypeNone){
        size = CGSizeZero;
    }else if(dialogType == TagViewDialogTypeKarma){
        size = CGSizeMake(DIALOG_WIDTH_FOR_KARMA, TEXT_HEIGHT);
    }

    return size;
}

- (NSString *)stringForDialog
{
    t_TagViewDialogType dialogType = [self getDialogType];

    NSString *string;
    if(dialogType == TagViewDialogTypeDetails){
        string = [NSString stringWithFormat:@"%@", [Brand getNameForBrandWithGUID:self.tagObject.brandGUID]];
    }else if(dialogType == TagViewDialogTypeDownReasons){
        string = [DownvoteReason getNameForDownvoteReasonWithGUID:self.tagObject.downvoteReasons.allKeys.lastObject] ?: @" ";
    }else{
        string = @"";
    }
    return string;
}

- (t_TagViewDialogType)getDialogType
{
    t_TagViewDialogType dialogType;
    if(self.allowVoting){
        if(self.tagObject.myVote == VoteNone){
            dialogType = TagViewDialogTypeNone;
        }else if(self.tagObject.myVote == VoteUp){
            if(self.reveal){
                dialogType = TagViewDialogTypeDetails;
            }else{
                dialogType = TagViewDialogTypeNone;
            }
        }else if(self.tagObject.myVote == VoteDown){
            dialogType = TagViewDialogTypeDownReasons;
        }
    }else{
        if(self.editing || self.reveal){
            dialogType = TagViewDialogTypeDetails;
        }else{
            dialogType = TagViewDialogTypeKarma;
        }
    }
    return dialogType;
}

- (CGColorRef)getColorForMyTag
{
    CGColorRef color;
    if((self.tagObject.upvotes - self.tagObject.downvotes) >= 0){
        color = COLOR_UPVOTE.CGColor;
    }else{
        color = COLOR_DOWNVOTE.CGColor;
    }
    return color;
}

////////////////////////////////////////////////////////////////////////
//
// IBAction Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark - IBAction Handlers
- (void)editProperties
{
    [self.delegate editPropertiesForTag:self.tagObject];
}

- (void)deleteSelf
{
    [[[UIAlertView alloc] initWithTitle:STR_TAG_DELETE_CONFIRM_TITLE
                                message:STR_TAG_DELETE_CONFIRM_MESSAGE
                               delegate:self
                      cancelButtonTitle:STR_TAG_DELETE_CONFIRM_CANCEL
                      otherButtonTitles:STR_TAG_DELETE_CONFIRM_DELETE, nil] show];
}

////////////////////////////////////////////////////////////////////////
//
// Gesture Handlers
//
////////////////////////////////////////////////////////////////////////
#pragma mark Gesture Handlers
- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    if(!self.reveal){
        if(self.allowEdit){
            if(self.editing){
                self.selected = YES;
                [self showContextMenu];
            }else{
                [self.delegate displayDownvoteReasonStatsDialogForTag:self.tagObject withView:self];
            }
        }else if(self.allowVoting){
            if(gesture.state == UIGestureRecognizerStateEnded){
                if(self.tagObject.myVote == VoteNone){
                    [self.tagObject setAndSaveUpvote];
                }else if(self.tagObject.myVote == VoteUp){
                    self.tagObject.myVote = VoteDown;       //set it here so that when we redraw it draws properly
                    [self.delegate displayDownvoteReasonDialogForTag:self.tagObject withView:self];
                }else if(self.tagObject.myVote == VoteDown){
                    [self.tagObject clearAndSaveVote];
                }
                
                [self setNeedsDisplay];
                [self.delegate changedVoteState];
            }
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    if(self.allowEdit){
        if(self.editing){
            if(gesture.state == UIGestureRecognizerStateBegan){
                self.selected = YES;
                [[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];

                self.center = [gesture locationInView:self.superview];
                [gesture setTranslation:CGPointZero inView:self.superview];
                
                self.dragging = YES;
                [self setNeedsDisplay];
            }else if(gesture.state == UIGestureRecognizerStateChanged){
                CGPoint delta = [gesture translationInView:self.superview];
                [gesture setTranslation:CGPointZero inView:self.superview];
                
                CGRect selfFrame = self.frame;
                selfFrame.origin.x+= delta.x;
                selfFrame.origin.y+= delta.y;
                self.frame = selfFrame;
            }else if(gesture.state == UIGestureRecognizerStateEnded){
                CGFloat maxX = self.superview.frame.size.width - PADDING;
                CGPoint position = [gesture locationInView:self.superview];
                if(position.x < PADDING) position.x = PADDING;
                if(position.x > maxX) position.x = maxX;
                self.tagObject.adjustedPosition = position;
                
                self.frame = [self frameForViewBasedOnTag:self.tagObject toFitIn:self.superview.frame.size];
                
                self.dragging = NO;
                [self setNeedsDisplay];
                
                [self showContextMenu];
            }
        }
    }
}

- (void)handleHold:(UILongPressGestureRecognizer *)gesture
{
    if(gesture.state == UIGestureRecognizerStateBegan){
        CGPoint tagCenter = [self convertPoint:self.tagObject.adjustedPosition fromView:self.superview];
        BOOL tagOnLeftSideOfScreen = (self.tagObject.adjustedPosition.x < (self.superview.frame.size.width / 2));
        
        CGFloat circleX = tagOnLeftSideOfScreen ? (PADDING + CIRCLE_RADIUS) : (self.frame.size.width - (PADDING + CIRCLE_RADIUS));
        if(fabs(circleX - tagCenter.x) < CIRCLE_RADIUS) circleX = tagCenter.x;              //if the circle will be on top of the tag, put the circle on the correct position.
        
        CGPoint circleCenter = CGPointMake(circleX, tagCenter.y);
        CGRect originForPopup = CGRectMake(circleCenter.x - CIRCLE_RADIUS, circleCenter.y, CIRCLE_RADIUS + CIRCLE_RADIUS, CIRCLE_RADIUS + CIRCLE_RADIUS);
        
        originForPopup = [self convertRect:originForPopup toView:self.superview];
        originForPopup.origin.y = self.frame.origin.y;
        
        TagViewPopup *popup = [[TagViewPopup alloc] init];
        [popup showInsideOfView:self.superview originatingFromRect:originForPopup withText:self.stringForDialog];
        self.popup = popup;
    }else if(gesture.state == UIGestureRecognizerStateEnded){
        [self.popup hide];
    }
}

#pragma mark - Protocol Implementation

////////////////////////////////////////////////////////////////////////
//
// UIView Overrides
//
////////////////////////////////////////////////////////////////////////
#pragma mark - UIView Overrides
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    //temporary border
//    CGContextSetLineWidth(context, 1);
//    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
//    CGContextStrokeRect(context, rect);

    //color setup
    CGColorRef color = self.selected ? COLOR_SELECTED.CGColor :
                                       self.allowVoting ? ((self.tagObject.myVote == VoteUp)   ? COLOR_UPVOTE :
                                                           (self.tagObject.myVote == VoteDown) ? COLOR_DOWNVOTE :
                                                                                                 COLOR_NOVOTE).CGColor :
                                                          [self getColorForMyTag];
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetFillColorWithColor(context, color);

    if(self.dragging){
        CGContextStrokeRect(context, CGRectMake((rect.size.width - rect.size.height) / 2,
                                                LINE_WIDTH / 2,
                                                rect.size.height - LINE_WIDTH,
                                                rect.size.height - LINE_WIDTH));
    }else{
        //calculate relevant values
        CGPoint tagCenter = [self convertPoint:self.tagObject.adjustedPosition fromView:self.superview];
        BOOL tagOnLeftSideOfScreen = (self.tagObject.adjustedPosition.x < (self.superview.frame.size.width / 2));

        CGFloat circleX = tagOnLeftSideOfScreen ? (PADDING + CIRCLE_RADIUS) : (rect.size.width - (PADDING + CIRCLE_RADIUS));
        if(fabs(circleX - tagCenter.x) < CIRCLE_RADIUS) circleX = tagCenter.x;              //if the circle will be on top of the tag, put the circle on the correct position.
        
        CGPoint circleCenter = CGPointMake(circleX, tagCenter.y);

        //determine if we'll draw a circle, or a "dialog"
        CGSize requiredDialogSize = [self sizeRequiredForDialog];
        requiredDialogSize.width+= MINI_PAD + MINI_PAD;
        BOOL drawCircle = (self.selected || (self.allowVoting && (self.tagObject.myVote != VoteDown)));        //only show circle if we're voting but haven't cast the vote.
        if(!drawCircle){
            if((self.tagObject.myVote == VoteDown) && ([self.tagObject.downvoteReasons.allKeys.lastObject length] == 0)){
                drawCircle = YES;                                                           //if downvote but no reason (probably because it hasn't been selected), show circle
            }else{
                CGFloat availableDialogWidth = rect.size.width - (PADDING + MIN_LINE_LENGTH);
                if(availableDialogWidth < requiredDialogSize.width){
                    drawCircle = YES;
                }
            }
        }

        //draw line
        CGContextSetLineWidth(context, LINE_WIDTH);
        CGContextMoveToPoint(context, tagCenter.x, tagCenter.y);
        CGContextAddLineToPoint(context, circleCenter.x, circleCenter.y);
        CGContextStrokePath(context);

        //draw circle or dialog
        if(drawCircle){
            BOOL drewWhatItCould = NO;
            if(self.reveal){
                self.holdGesture.enabled = YES;
                self.pulsating = YES;
                drewWhatItCould = [self showWhatYouCanInRect:rect onLeft:tagOnLeftSideOfScreen usingContext:context];
            }
            
            if(!drewWhatItCould){
                CGRect circleRect = CGRectMake(circleCenter.x - CIRCLE_RADIUS,
                                               circleCenter.y - CIRCLE_RADIUS,
                                               CIRCLE_RADIUS + CIRCLE_RADIUS,
                                               CIRCLE_RADIUS + CIRCLE_RADIUS);
                CGContextFillEllipseInRect(context, circleRect);
            }
        }else{
            CGRect dialogRect = CGRectMake(tagOnLeftSideOfScreen ? PADDING : (rect.size.width - requiredDialogSize.width - PADDING),
                                           LINE_OFFSET - LINE_WIDTH,
                                           requiredDialogSize.width,
                                           TEXT_HEIGHT);
            CGContextFillRect(context, dialogRect);
            
            if([self getDialogType] == TagViewDialogTypeKarma){
                NSDictionary *attrs = @{NSFontAttributeName:[self fontForDialog]};
                
                UIImage *upImg = [UIImage imageNamed:@"tagViewUpvote.png"];
                UIImage *dnImg = [UIImage imageNamed:@"tagViewDownvote.png"];
                
                NSString *upString = [NSString stringWithFormat:@"%i", self.tagObject.upvotes];
                NSString *dnString = [NSString stringWithFormat:@"%i", self.tagObject.downvotes];
                
                CGSize upSize = [upString sizeWithAttributes:attrs];
                CGSize dnSize = [dnString sizeWithAttributes:attrs];
                
                CGFloat upX = dialogRect.origin.x + KARMA_PADDING + MINI_PAD;
                CGFloat dnX = dialogRect.origin.x + dialogRect.size.width - (KARMA_PADDING + dnSize.width + upImg.size.width + MINI_PAD);

                CGFloat upImgX = upX + upSize.width + KARMA_MINI_PAD;
                CGFloat dnImgX = dnX + dnSize.width + KARMA_MINI_PAD;
                
                [upString drawAtPoint:CGPointMake(upX, dialogRect.origin.y + ((TEXT_HEIGHT - upSize.height) / 2)) withAttributes:attrs];
                [dnString drawAtPoint:CGPointMake(dnX, dialogRect.origin.y + ((TEXT_HEIGHT - dnSize.height) / 2)) withAttributes:attrs];

                [upImg drawAtPoint:CGPointMake(upImgX, KARMA_UP_MAGIC_Y_PAD   + dialogRect.origin.y + ((TEXT_HEIGHT - upImg.size.height) / 2))];
                [dnImg drawAtPoint:CGPointMake(dnImgX, KARMA_DOWN_MAGIC_Y_PAD + dialogRect.origin.y + ((TEXT_HEIGHT - dnImg.size.height) / 2))];
            }else{
                NSString *string = [self stringForDialog];
                [string drawAtPoint:CGPointMake(dialogRect.origin.x + MINI_PAD,
                                                dialogRect.origin.y + ((TEXT_HEIGHT - requiredDialogSize.height) / 2))
                     withAttributes:@{NSFontAttributeName:[self fontForDialog]}];
            }
        }
    }
}

- (BOOL)showWhatYouCanInRect:(CGRect)rect
                      onLeft:(BOOL)onLeft
                usingContext:(CGContextRef)context
{
    BOOL success = NO;
    
    CGFloat availableDialogWidth = rect.size.width - (PADDING + MIN_LINE_LENGTH);

    NSString *string = [self stringForDialog];                                                              //get string
    if(string.length) string = [NSString stringWithFormat:@"%@...", [string substringToIndex:string.length - 1]];             //remove last char and add ...
    CGSize requiredSize = [string sizeWithAttributes:@{NSFontAttributeName:self.fontForDialog}];
    CGFloat requiredWidth = requiredSize.width + MINI_PAD + MINI_PAD;
    CGFloat requiredHeight = requiredSize.height;
    
    while((string.length > 3) && (requiredWidth > availableDialogWidth)){                                   //until we chop off all the string or we can actually fit it
        string = [NSString stringWithFormat:@"%@...", [string substringToIndex:string.length - 4]];         //remove last 4 chars (... + last char) and re-add ...
        requiredWidth = [string sizeWithAttributes:@{NSFontAttributeName:self.fontForDialog}].width + MINI_PAD + MINI_PAD;
    }
    
    if(requiredWidth <= availableDialogWidth){  //if we don't even have space to draw the "...", then do nothing. Otherwise, draw the text
        CGRect dialogRect = CGRectMake(onLeft ? PADDING : (rect.size.width - requiredWidth - PADDING),
                                       LINE_OFFSET - LINE_WIDTH,
                                       requiredWidth,
                                       TEXT_HEIGHT);
        CGContextFillRect(context, dialogRect);

        [string drawAtPoint:CGPointMake(dialogRect.origin.x + MINI_PAD,
                                        dialogRect.origin.y + ((TEXT_HEIGHT - requiredHeight) / 2))
             withAttributes:@{NSFontAttributeName:[self fontForDialog]}];
        
        success = YES;
    }
    
    return success;
}


- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == ALERT_DELETE_CANCEL_INDEX){
        //do nothing
    }else if(buttonIndex == ALERT_DELETE_DELETE_INDEX){
        [self.delegate deleteTag:self.tagObject
                andRemoveTagView:self];
    }
}


@end
