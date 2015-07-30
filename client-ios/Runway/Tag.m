//
//  Tag.m
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "Tag.h"
#import "DownvoteReason.h"

#import "RunwayServices.h"

@interface Tag()
@property (nonatomic) BOOL changesAreSaved;
@property (nonatomic) BOOL needsToSaveVote;
@end

@implementation Tag

////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
#pragma mark - Getters/Setters
- (void)setClothingGUID:(NSString *)clothingGUID
{
    _clothingGUID = clothingGUID;
    self.changesAreSaved = NO;
}

- (void)setBrandGUID:(NSString *)brandGUID
{
    _brandGUID = brandGUID;
    self.changesAreSaved = NO;
}

- (void)setPosition:(CGPoint)position
{
    _position = position;
    self.changesAreSaved = NO;
}

- (int)karma
{
    return (self.upvotes - self.downvotes);
}

- (int)percentUpvoted
{
    return ((self.upvotes * 100)/(self.upvotes + self.downvotes));
}

- (CGPoint)adjustedPosition
{
    return CGPointMake(self.position.x * self.scaleFactor.x, self.position.y * self.scaleFactor.y);
}

- (void)setAdjustedPosition:(CGPoint)adjustedPosition
{
    self.position = CGPointMake(adjustedPosition.x / self.scaleFactor.x, adjustedPosition.y / self.scaleFactor.y);
}

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (Tag *)initWithGUID:(NSString *)GUID                          //can be nil if new.
     forParentImageID:(NSString *)parentImageGUID               //can be nil if new image
    usingClothingGUID:(NSString *)clothingGUID
         andBrandGUID:(NSString *)brandGUID
             position:(CGPoint)position
      downvoteReasons:(NSDictionary *)downvoteReasons           //can be nil if new. will be init to empty.
               myVote:(t_Vote)myVote
               iOwnIt:(BOOL)iOwnIt
{
    if(self = [super init]){
        self.GUID = GUID;
        self.parentImageGUID = parentImageGUID;
        self.clothingGUID = clothingGUID;
        self.brandGUID = brandGUID;
        self.position = position;
        self.downvoteReasons = downvoteReasons ? downvoteReasons : @{};
        self.myVote = myVote;
        self.iOwnIt = iOwnIt;
        
        self.changesAreSaved = YES;
    }
    return self;
}

- (void)clearAndSaveVote
{
    self.myVote = VoteNone;
    self.needsToSaveVote = NO;
}

- (void)setAndSaveUpvote
{
    self.myVote = VoteUp;
    self.needsToSaveVote = YES;
}

- (void)setAndSaveDownvoteWithReason:(DownvoteReason *)downvoteReason
{
    self.myVote = VoteDown;
    self.downvoteReasons = @{downvoteReason.GUID : @(1)};

    self.needsToSaveVote = YES;
}

- (void)saveEditChanges
{
    if(!self.changesAreSaved){
        if(self.GUID.length){
            self.changesAreSaved = YES;

            [RunwayServices editTagWithGUID:self.GUID
                                    atPoint:self.position
                           withClothingGUID:self.clothingGUID
                               andBrandGUID:self.brandGUID];
        }else if(self.parentImageGUID.length){
            self.changesAreSaved = YES;

            self.GUID = [RunwayServices createNewTagForImageWithGUID:self.parentImageGUID
                                                             atPoint:self.position
                                                    withClothingGUID:self.clothingGUID
                                                        andBrandGUID:self.brandGUID];
        }
    }
}

- (void)saveVoteIfNecessary
{
    if(self.needsToSaveVote){
        NSString *downvoteReasonGUID = (self.myVote == VoteDown) ? self.downvoteReasons.allKeys.lastObject : nil;
        dispatch_async(dispatch_queue_create("save vote", NULL), ^{
            [RunwayServices setVoteForTagWithGUID:self.GUID
                                           toVote:self.myVote
                            andDownvoteReasonGUID:downvoteReasonGUID];
        });
    }
}

#pragma mark Helper Functions
#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - UIViewController Overrides

@end
