//
//  Brand.h
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Brand : NSObject

+ (NSArray *)getTypesAndNames;
+ (NSArray *)getTypesAndNamesForcingServerFetch;

+ (NSString *)getNameForBrandWithGUID:(NSString *)GUID;

@property (nonatomic, strong) NSString *GUID;
@property (nonatomic, strong) NSString *name;

- (Brand *)initWithGUID:(NSString *)GUID
                andName:(NSString *)name;

@end
