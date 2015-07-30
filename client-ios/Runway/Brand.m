//
//  Brand.m
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "Brand.h"
#import "RunwayServices.h"

@implementation Brand

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
+ (NSArray *)getTypesAndNames
{
    NSArray *brands = [self setArray:NO to:nil];
    if(!brands){
        brands = [self getTypesAndNamesForcingServerFetch];
        [self setArray:YES to:brands];
    }
    return brands;
}

+ (NSArray *)getTypesAndNamesForcingServerFetch
{
    NSArray *brands = [RunwayServices getBrandNames];
    [self setArray:YES to:brands];
    return brands;
}

+ (NSString *)getNameForBrandWithGUID:(NSString *)GUID
{
    NSArray *brands = [self getTypesAndNames];
    
    NSString *name = nil;
    for(Brand *i in brands){
        if([i.GUID isEqualToString:GUID]){
            name = i.name;
            break;
        }
    }
    return name;
}

- (Brand *)initWithGUID:(NSString *)GUID
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
