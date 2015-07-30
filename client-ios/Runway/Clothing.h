//
//  Clothing.h
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Clothing : NSObject

+ (NSArray *)getTypesAndNames;
+ (NSArray *)getTypesAndNamesForcingServerFetch;

+ (NSString *)getNameForClothingWithGUID:(NSString *)GUID;

@property (nonatomic, strong) NSString *GUID;
@property (nonatomic, strong) NSString *name;

- (Clothing *)initWithGUID:(NSString *)GUID
                   andName:(NSString *)name;

@end
