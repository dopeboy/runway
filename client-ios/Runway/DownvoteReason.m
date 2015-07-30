//
//  DownvoteReason.m
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "DownvoteReason.h"
#import "RunwayServices.h"

@implementation DownvoteReason

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
+ (NSArray *)getTypesAndNames
{
    NSArray *reasons = [self setArray:NO to:nil];
    if(!reasons){
        reasons = [self getTypesAndNamesForcingServerFetch];
        [self setArray:YES to:reasons];
    }
    return reasons;
}

+ (NSArray *)getTypesAndNamesForcingServerFetch
{
    NSArray *reasons = [RunwayServices getDownvoteReasons];
    [self setArray:YES to:reasons];
    return reasons;
}

+ (NSString *)getNameForDownvoteReasonWithGUID:(NSString *)GUID
{
    NSArray *reasons = [self getTypesAndNames];

    NSString *name = nil;
    for(DownvoteReason *i in reasons){
        if([i.GUID isEqualToString:GUID]){
            name = i.name;
            break;
        }
    }
    return name;
}

- (DownvoteReason *)initWithGUID:(NSString *)GUID
                         andName:(NSString *)name
{
    if(self = [super init]){
        self.GUID = GUID;
        self.name = name;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
+ (NSArray *)setArray:(BOOL)set
                   to:(NSArray *)array
{
    static NSArray *cache = nil;
    
    if(set){
        cache = array;
    }
    
    return cache;
}

#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - UIViewController Overrides

@end
