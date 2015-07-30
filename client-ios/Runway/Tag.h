//
//  Tag.h
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum{
    VoteDown = -1,
    VoteNone = 0,
    VoteUp = 1,
}t_Vote;

@class DownvoteReason;

@interface Tag : NSObject

@property (nonatomic, strong) NSString *GUID;
@property (nonatomic, strong) NSString *parentImageGUID;
@property (nonatomic, strong) NSString *clothingGUID;
@property (nonatomic, strong) NSString *brandGUID;
@property (nonatomic) CGPoint position;
@property (nonatomic) CGPoint adjustedPosition;
@property (nonatomic) CGPoint scaleFactor;
@property (nonatomic, strong) NSDictionary *downvoteReasons;    //reasonGUID -> count
@property (nonatomic) int upvotes;
@property (nonatomic) int downvotes;
@property (nonatomic, readonly) int karma;                      //calculated from (upvote - downvote)
@property (nonatomic, readonly) int percentUpvoted;             //calculated and rounded from (upvote/(upvote + downvote))
@property (nonatomic) t_Vote myVote;
@property (nonatomic) BOOL iOwnIt;

- (Tag *)initWithGUID:(NSString *)GUID                          //can be nil if new.
     forParentImageID:(NSString *)parentImageGUID               //can be nil if new image
    usingClothingGUID:(NSString *)clothingGUID
         andBrandGUID:(NSString *)brandGUID
             position:(CGPoint)position
      downvoteReasons:(NSDictionary *)downvoteReasons           //can be nil if new. will be init to empty.
               myVote:(t_Vote)myVote
               iOwnIt:(BOOL)iOwnIt;

- (void)clearAndSaveVote;
- (void)setAndSaveUpvote;
- (void)setAndSaveDownvoteWithReason:(DownvoteReason *)downvoteReason;

- (void)saveEditChanges;                                        //if GUID is nil, it will be created as a new one, and the property will be set with what's returned
- (void)saveVoteIfNecessary;
@end
