//
//  Clothing.m
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "Clothing.h"
#import "RunwayServices.h"

@implementation Clothing

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
+ (NSArray *)getTypesAndNames
{
    NSArray *clothings = [self setArray:NO to:nil];
    if(!clothings){
        clothings = [self getTypesAndNamesForcingServerFetch];
        [self setArray:YES to:clothings];
    }
    return clothings;
}

+ (NSArray *)getTypesAndNamesForcingServerFetch
{
    NSArray *clothings = [RunwayServices getClothingTypes];
    [self setArray:YES to:clothings];
    return clothings;
}

+ (NSString *)getNameForClothingWithGUID:(NSString *)GUID
{
    NSArray *clothings = [self getTypesAndNames];
    
    NSString *name = nil;
    for(Clothing *i in clothings){
        if([i.GUID isEqualToString:GUID]){
            name = i.name;
            break;
        }
    }
    return name;
}

- (Clothing *)initWithGUID:(NSString *)GUID
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
