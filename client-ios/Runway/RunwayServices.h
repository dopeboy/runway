//
//  RunwayServices.h
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tag.h"

#define NOTIFICATION_KARMA_UPDATED      @"NOTIFICATION_KARMA_UPDATED"

@class Image;
@interface RunwayServices : NSObject

+ (NSString *)accessToken;

+ (void)loginOnSeparateThreadWithCompletionBlock:(void (^)(NSString *errorMessage))callbackBlock;

+ (NSArray *)getMyImages;
+ (NSArray *)getFavoriteImages;
+ (NSDictionary *)getLeaderboardImages;

+ (Image *)getImageWithGUID:(NSString *)imageGUID;
+ (Image *)getNextImage;

+ (BOOL)setVoteForTagWithGUID:(NSString *)tagGUID
                       toVote:(t_Vote)vote
        andDownvoteReasonGUID:(NSString *)downvoteReasonGUID;   //downvoteReasonGUID is nil if vote is not downvote.

+ (NSArray *)getClothingTypes;
+ (NSArray *)getBrandNames;
+ (NSArray *)getDownvoteReasons;

+ (BOOL)getVoteInformationForTagWithGUID:(NSString *)tagGUID
                   andStoreUpvoteCountIn:(NSInteger *)upvotePointer
                         downvoteCountIn:(NSInteger *)downvotePointer
                      andReasonsCountsIn:(NSDictionary **)reasonsPointer;

+ (NSString *)createNewTagForImageWithGUID:(NSString *)imageGUID
                                   atPoint:(CGPoint)point
                          withClothingGUID:(NSString *)clothingGUID
                              andBrandGUID:(NSString *)brandGUID;

+ (BOOL)editTagWithGUID:(NSString *)tagGUID
                atPoint:(CGPoint)point
       withClothingGUID:(NSString *)clothingGUID
           andBrandGUID:(NSString *)brandGUID;

+ (BOOL)deleteTagWithGUID:(NSString *)tagGUID;

+ (BOOL)saveNewImage:(Image *)image;
+ (BOOL)deleteImageWithGUID:(NSString *)imageGUID;

@end
