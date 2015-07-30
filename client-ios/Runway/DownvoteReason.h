//
//  DownvoteReason.h
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownvoteReason : NSObject

+ (NSArray *)getTypesAndNames;
+ (NSArray *)getTypesAndNamesForcingServerFetch;

+ (NSString *)getNameForDownvoteReasonWithGUID:(NSString *)GUID;

@property (nonatomic, strong) NSString *GUID;
@property (nonatomic, strong) NSString *name;

- (DownvoteReason *)initWithGUID:(NSString *)GUID
                         andName:(NSString *)name;

@end
