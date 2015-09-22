//
//  RunwayServices.m
//  Runway
//
//  Created by Roberto Cordon on 5/21/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "RunwayServices.h"
#import "Image.h"
#import "Tag.h"
#import "Clothing.h"
#import "Brand.h"
#import "DownvoteReason.h"

#import "AmazonServices.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#define BASE_URL                    @"https://enigmatic-garden-4019.herokuapp.com"
#define DEFAULTS_CODE               @"defaults access code"

typedef enum{
    HTTPMethodGet,
    HTTPMethodPost,
    HTTPMethodPut,
    HTTPMethodDelete,
}t_HTTPMethod;

@implementation RunwayServices

#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
+ (void)loginOnSeparateThreadWithCompletionBlock:(void (^)(NSString *errorMessage))callbackBlock
{
    dispatch_async(dispatch_queue_create("login", NULL), ^{
        NSMutableDictionary *dataToSend = [@{
                                             @"fb_access_token" : [FBSDKAccessToken currentAccessToken].tokenString,
                                             } mutableCopy];

        //load invite code from defaults and attach to "data to send" if it's there.
        NSString *accessCode = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_CODE];
        if(accessCode) dataToSend[@"invite_code"] = accessCode;

        NSDictionary *returnData = [self getJSONFromPath:@"/login/"
                                         usingHTTPMethod:HTTPMethodPost
                                             sendingData:dataToSend];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(returnData){
                NSString *errorMessage = [returnData[@"error"] lastObject];
                if([errorMessage isEqualToString:@"code_required"] || [errorMessage isEqualToString:@"code_incorrect"]){
                    callbackBlock(errorMessage);
                }else{
                    [self setAccessToken:returnData[@"access_token"]];
                    
                    [self getClothingTypesFromDictionary:returnData[@"clothing_types"]];
                    [self getBrandNamesFromDictionary:returnData[@"brands"]];
                    [self getDownvoteReasonsFromDictionary:returnData[@"downvote_reasons"]];
                    
                    callbackBlock(nil);
                }
            }else{
                [self setAccessToken:@""];
                callbackBlock(@"unkown");
            }
        });
    });
}

+ (NSArray *)getMyImages
{
    NSDictionary *returnData = [self getJSONFromPath:@"/photos/"
                                usingHTTPMethod:HTTPMethodGet
                                    sendingData:@{
                                                  //nothing
                                                  }
                           ];
    
    NSArray *imageData = returnData[@"images"];
    
    NSMutableArray *myImages = [NSMutableArray arrayWithCapacity:imageData.count];
    for(NSDictionary *item in imageData){
        [myImages addObject:[self imageFromDictionary:item iOwnIt:YES]];
    }

    return myImages;
}

+ (NSArray *)getFavoriteImages
{
    NSDictionary *returnData = [self getJSONFromPath:@"/photos/favorites/"
                                usingHTTPMethod:HTTPMethodGet
                                    sendingData:@{
                                                  //nothing
                                                  }
                           ];
    
    NSArray *imageData = returnData[@"images"];

    NSMutableArray *favoriteImages = [NSMutableArray arrayWithCapacity:imageData.count];
    for(NSDictionary *item in imageData){
        [favoriteImages addObject:[self imageFromDictionary:item iOwnIt:NO]];
    }
    
    return favoriteImages;
}

+ (NSDictionary *)getLeaderboardImages
{
    NSDictionary *returnData = [self getJSONFromPath:@"/users/leaderboard/"
                                     usingHTTPMethod:HTTPMethodPost
                                         sendingData:@{
                                                       @"fb_access_token" : [FBSDKAccessToken currentAccessToken].tokenString,
                                                       }
                                ];
    
    NSMutableArray *friends = [NSMutableArray arrayWithCapacity:[returnData[@"friends"] count]];
    for(NSDictionary *item in returnData[@"friends"]){
        [friends addObject:[self imageFromDictionary:item iOwnIt:NO]];
    }
    NSMutableArray *others = [NSMutableArray arrayWithCapacity:[returnData[@"others"] count]];
    for(NSDictionary *item in returnData[@"others"]){
        [others addObject:[self imageFromDictionary:item iOwnIt:NO]];
    }
    
    return @{
             @"friends" : friends,
             @"others"  : others,
             };
}

+ (Image *)getImageWithGUID:(NSString *)imageGUID
{
    BOOL iOwnIt    = (imageGUID != nil);
    NSString *path = (imageGUID != nil) ? [NSString stringWithFormat:@"/photos/%@/", imageGUID] : @"/photos/next/";
    
    NSDictionary *returnData = [self getJSONFromPath:path
                                     usingHTTPMethod:HTTPMethodGet
                                         sendingData:@{
                                                       //nothing
                                                       }
                                ];

    return [self imageFromDictionary:returnData[@"image"] iOwnIt:iOwnIt];
}

+ (Image *)getNextImage
{
    return [self getImageWithGUID:nil];
}

+ (BOOL)setVoteForTagWithGUID:(NSString *)tagGUID
                       toVote:(t_Vote)vote
        andDownvoteReasonGUID:(NSString *)downvoteReasonGUID;   //downvoteReasonGUID is nil if vote is not downvote.
{
    NSArray *returnData = nil;
    
    int voteValue = (vote == VoteDown) ? -1 :
                    (vote == VoteUp)   ?  1 : 0;
    
    NSMutableDictionary *dataToSend = [@{
                                         @"tag_uuid"               : tagGUID,
                                         @"value"                  : @(voteValue),
                                         } mutableCopy];
    if(downvoteReasonGUID) dataToSend[@"downvote_reason_uuid"] = downvoteReasonGUID;
    
    if(voteValue != 0){
        returnData = [self getJSONFromPath:@"/votes/"
                           usingHTTPMethod:HTTPMethodPost
                               sendingData:dataToSend
                      ];
    }
    return (returnData != nil);
}

+ (NSArray *)getClothingTypes
{
    return [self getClothingTypesFromDictionary:nil];
}

+ (NSArray *)getBrandNames
{
    return [self getBrandNamesFromDictionary:nil];
}

+ (NSArray *)getDownvoteReasons
{
    return [self getDownvoteReasonsFromDictionary:nil];
}

+ (BOOL)getVoteInformationForTagWithGUID:(NSString *)tagGUID
                   andStoreUpvoteCountIn:(NSInteger *)upvotePointer
                         downvoteCountIn:(NSInteger *)downvotePointer
                      andReasonsCountsIn:(NSDictionary **)reasonsPointer
{
    NSDictionary *returnData = [self getJSONFromPath:[NSString stringWithFormat:@"/tags/%@/", tagGUID]
                                     usingHTTPMethod:HTTPMethodGet
                                         sendingData:@{
                                                       //nothing
                                                       }
                                ];
    
    NSMutableDictionary *reasons = [NSMutableDictionary dictionaryWithCapacity:[returnData[@"downvotereason_summary"] count]];
    for(NSDictionary *item in returnData[@"downvotereason_summary"]){
        NSNumber *count = item[@"count"];
        if([count intValue] > 0){
            reasons[item[@"downvotereason_label"]] = count;
        }
    }
    
    
    if(upvotePointer)   *upvotePointer   = [returnData[@"upvote_total"] intValue];
    if(downvotePointer) *downvotePointer = abs([returnData[@"downvote_total"] intValue]);
    if(reasonsPointer)  *reasonsPointer  = reasons;
    
    return (reasons != nil);
}

+ (NSString *)createNewTagForImageWithGUID:(NSString *)imageGUID
                                   atPoint:(CGPoint)point
                          withClothingGUID:(NSString *)clothingGUID
                              andBrandGUID:(NSString *)brandGUID
{
    NSDictionary *returnData = [self getJSONFromPath:@"/tags/"
                                     usingHTTPMethod:HTTPMethodPost
                                         sendingData:@{
                                                       @"img_uuid"           : imageGUID,
                                                       @"point_x"            : @(round(point.x)),
                                                       @"point_y"            : @(round(point.y)),
                                                       @"clothing_type_uuid" : clothingGUID,
                                                       @"brand_uuid"         : brandGUID,
                                                       }
                                ];
    
    return returnData[@"tag_uuid"];
}

+ (BOOL)editTagWithGUID:(NSString *)tagGUID
                atPoint:(CGPoint)point
       withClothingGUID:(NSString *)clothingGUID
           andBrandGUID:(NSString *)brandGUID
{
    NSDictionary *returnData = [self getJSONFromPath:[NSString stringWithFormat:@"/tags/%@/", tagGUID]
                                     usingHTTPMethod:HTTPMethodPut
                                         sendingData:@{
                                                       @"point_x"            : @(round(point.x)),
                                                       @"point_y"            : @(round(point.y)),
                                                       @"clothing_type_uuid" : clothingGUID,
                                                       @"brand_uuid"         : brandGUID,
                                                       }
                                ];
    
    return (returnData != nil);
}

+ (BOOL)deleteTagWithGUID:(NSString *)tagGUID
{
    NSDictionary *returnData = [self getJSONFromPath:[NSString stringWithFormat:@"/tags/%@/", tagGUID]
                                     usingHTTPMethod:HTTPMethodDelete
                                         sendingData:@{
                                                       //nothing
                                                       }
                                ];
    
    return (returnData != nil);
}

+ (BOOL)saveNewImage:(Image *)image
{
    BOOL success = NO;
    
    NSString *amazonImageUUID = NSUUID.UUID.UUIDString;
    BOOL uploadSuccess = [AmazonServices uploadFullImage:image.fullImage
                                       andThumbnailImage:image.thumbnailImage
                                                withUUID:amazonImageUUID];
    
    if(uploadSuccess){
        NSMutableArray *tags = [NSMutableArray arrayWithCapacity:image.tags.count];
        for(Tag *tag in image.tags){
            [tags addObject:@{
                              @"point_x"            : @(round(tag.position.x)),
                              @"point_y"            : @(round(tag.position.y)),
                              @"clothing_type_uuid" : tag.clothingGUID,
                              @"brand_uuid"         : tag.brandGUID,
                              }];
        }
        
        NSDictionary *returnData = [self getJSONFromPath:@"/photos/"
                                         usingHTTPMethod:HTTPMethodPost
                                             sendingData:@{
                                                           @"img_url"        : amazonImageUUID,
                                                           @"thumb_img_url"  : amazonImageUUID,
                                                           @"tags"           : tags,
                                                           }
                                    ];
        
        image.GUID = returnData[@"img_uuid"];
        
        success = (returnData != nil);
    }
    return success;
}

+ (BOOL)deleteImageWithGUID:(NSString *)imageGUID
{
    NSDictionary *returnData = [self getJSONFromPath:[NSString stringWithFormat:@"/photos/%@/", imageGUID]
                                     usingHTTPMethod:HTTPMethodDelete
                                         sendingData:@{
                                                       //nothing
                                                       }
                                ];
    
    return (returnData != nil);
}

+ (NSInteger)readKarma
{
    return [self setKarma:NO to:0];
}

+ (void)writeKarma:(NSInteger)karma
{
    [self setKarma:YES to:karma];
}

+ (NSInteger)setKarma:(BOOL)set
                   to:(NSInteger)karma
{
    static NSInteger cache = 0;
    
    if(set){
        cache = karma;
    }
    
    return cache;
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
+ (id)getJSONFromPath:(NSString *)urlPath
      usingHTTPMethod:(t_HTTPMethod)method
          sendingData:(NSDictionary *)data
{
    NSError *jsonEncodingError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonEncodingError];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BASE_URL, urlPath]]];
    request.HTTPMethod = [self stringForHTTPMethod:method];
    if(data.count) [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if(![urlPath isEqualToString:@"/login/"]) [request setValue:[NSString stringWithFormat:@"Token %@", [self accessToken]] forHTTPHeaderField:@"Authorization"];

    //make request and parse JSON data
    NSHTTPURLResponse *response;
    NSError *httpError;
    NSData *serverData = [NSURLConnection sendSynchronousRequest:request
                                               returningResponse:&response
                                                           error:&httpError];

    if(response.statusCode == 403){
        //we will deal with this below once the data is parsed.
    }else if((response.statusCode < 200) || (response.statusCode > 299)){
        if([urlPath isEqualToString:@"/login/"] && (response.statusCode == 400)){
            //here, we got a 400 trying to log in, which is acceptable.
        }else{
            [self logHTTPError:[NSString stringWithFormat:@"HTTP(%@) %zd for request to '%@' with data: %@",//\n%@",
                                request.HTTPMethod,
                                response.statusCode,
                                urlPath,
                                jsonString//,
                                //[NSString stringWithUTF8String:serverData.bytes]
                                ]
             ];
            
            serverData = nil;
        }
    }else if(httpError){
        [self logHTTPError:[NSString stringWithFormat:@"OTHER ERROR: %@", httpError.localizedDescription]];
        serverData = nil;
    }
    
    NSError *jsonDecodingError;
    __block id jsonReceivedData = serverData.length ? [NSJSONSerialization JSONObjectWithData:serverData options:0 error:&jsonDecodingError] : nil;
    if(jsonDecodingError){
        NSLog(@"JSON ERROR: %@", jsonDecodingError.localizedDescription);
        jsonReceivedData = nil;
    }
    
    if(response.statusCode == 403){
        static BOOL retying = NO; //prevents us from retrying more than once going deeper
        if(!retying && [jsonReceivedData isKindOfClass:[NSDictionary class]] && [jsonReceivedData[@"detail"] isEqualToString:@"Token has expired"]){
            retying = YES;
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [self loginOnSeparateThreadWithCompletionBlock:^(NSString *errorMessage){
                if(!errorMessage){
                    //retry
                    jsonReceivedData = [self getJSONFromPath:urlPath usingHTTPMethod:method sendingData:data];
                }else{
                    jsonReceivedData = nil;
                }
                retying = NO;
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);  //this here will wait until we call dispatch_semaphore_signal on self.semaphore
            semaphore = nil;
        }else{
            [self logHTTPError:[NSString stringWithFormat:@"HTTP(%@) %zd for request to '%@' with data: %@", request.HTTPMethod, response.statusCode, urlPath, jsonString]];
        }
        jsonReceivedData = nil;
    }

    if([jsonReceivedData isKindOfClass:[NSDictionary class]] && jsonReceivedData[@"user_karma"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self writeKarma:[jsonReceivedData[@"user_karma"] integerValue]];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KARMA_UPDATED
                                                                object:self
                                                              userInfo:@{NOTIFICATION_KARMA_UPDATED : jsonReceivedData[@"user_karma"]}];
        });
    }
    
    return jsonReceivedData;
}

+ (NSString *)stringForHTTPMethod:(t_HTTPMethod)method
{
    return  (method == HTTPMethodGet)    ? @"GET"    :
            (method == HTTPMethodPost)   ? @"POST"   :
            (method == HTTPMethodPut)    ? @"PUT"    :
            (method == HTTPMethodDelete) ? @"DELETE" : @"";
}

+ (void)logHTTPError:(NSString *)errorString
{
    NSLog(@"%@", errorString);
}

+ (void)setAccessToken:(NSString *)token
{
    [self accessTokenManager:token];
}

+ (NSString *)accessToken
{
    return [self accessTokenManager:nil];
}

+ (NSString *)accessTokenManager:(NSString *)newAccessToken
{
    static NSString *accessToken;
    if(newAccessToken) accessToken = newAccessToken;
    return accessToken;
}

+ (Image *)imageFromDictionary:(NSDictionary *)item
                        iOwnIt:(BOOL)iOwnIt
{
    NSString *imageGUID = item[@"img_uuid"];
    
    NSMutableArray *tags = [NSMutableArray arrayWithCapacity:[item[@"tags"] count]];
    for(NSDictionary *tagItem in item[@"tags"]){
        [tags addObject:[self tagFromDictionary:tagItem
                                  withImageGUID:imageGUID
                                         iOwnIt:YES]];
    }
    
    return [[Image alloc] initWithGUID:imageGUID
                                 title:item[@"description"]
                     thumbnailImageURL:item[@"thumb_img_url"]
                          fullImageURL:item[@"img_url"]
                           andTagArray:tags
                                iOwnIt:iOwnIt];
}

+ (Tag *)tagFromDictionary:(NSDictionary *)item
             withImageGUID:(NSString *)imageGUID
                    iOwnIt:(BOOL)iOwnIt
{
    int voteInt = [item[@"my_vote"] intValue];
    t_Vote tagVote = (voteInt == -1) ? VoteDown :
    (voteInt ==  1) ? VoteUp   : VoteNone;
    
    Tag *tag = [[Tag alloc] initWithGUID:item[@"tag_uuid"]
                        forParentImageID:imageGUID
                       usingClothingGUID:item[@"clothing_type_uuid"]
                            andBrandGUID:item[@"brand_uuid"]
                                position:CGPointMake([item[@"point_x"] doubleValue], [item[@"point_y"] doubleValue])
                         downvoteReasons:nil
                                  myVote:tagVote
                                  iOwnIt:iOwnIt];
    
    tag.upvotes = [item[@"upvote_total"] intValue];
    tag.downvotes = abs([item[@"downvote_total"] intValue]);
    
    NSMutableDictionary *downvoteReasons = [NSMutableDictionary dictionaryWithCapacity:[item[@"downvotereason_summary"] count]];
    for(NSDictionary *downvoteReasonItem in item[@"downvotereason_summary"]){
        NSNumber *count = downvoteReasonItem[@"count"];
        if([count intValue] > 0){
            downvoteReasons[downvoteReasonItem[@"downvotereason_uuid"]] = count;
        }
    }
    tag.downvoteReasons = downvoteReasons;
    
    return tag;
}

+ (NSArray *)getClothingTypesFromDictionary:(NSDictionary *)data
{
    static NSArray *cache = nil;
    if(!cache){
        NSArray *returnData = data ?: [self getJSONFromPath:@"/clothingtypes/"
                                            usingHTTPMethod:HTTPMethodGet
                                                sendingData:@{
                                                              //nothing
                                                              }
                                       ];
        
        NSMutableArray *clothingTypes = [NSMutableArray arrayWithCapacity:returnData.count];
        for(NSDictionary *item in returnData){
            [clothingTypes addObject:[[Clothing alloc] initWithGUID:item[@"clothing_type_uuid"]
                                                            andName:item[@"clothing_type_label"]]];
        }
        
        cache = clothingTypes;
    }
    return cache;
}

+ (NSArray *)getBrandNamesFromDictionary:(NSDictionary *)data
{
    static NSArray *cache = nil;
    if(!cache){
        NSArray *returnData = data ?: [self getJSONFromPath:@"/brands/"
                                            usingHTTPMethod:HTTPMethodGet
                                                sendingData:@{
                                                              //nothing
                                                              }
                                       ];
        
        NSMutableArray *brandNames = [NSMutableArray arrayWithCapacity:returnData.count];
        for(NSDictionary *item in returnData){
            [brandNames addObject:[[Brand alloc] initWithGUID:item[@"brand_uuid"]
                                                      andName:item[@"brand_name"]]];
        }
        
        cache = brandNames;
    }
    return cache;
}

+ (NSArray *)getDownvoteReasonsFromDictionary:(NSDictionary *)data
{
    static NSArray *cache = nil;
    if(!cache){
        NSArray *returnData = data ?: [self getJSONFromPath:@"/downvotereasons/"
                                            usingHTTPMethod:HTTPMethodGet
                                                sendingData:@{
                                                              //nothing
                                                              }
                                       ];
        
        NSMutableArray *downvoteReasons = [NSMutableArray arrayWithCapacity:returnData.count];
        for(NSDictionary *item in returnData){
            [downvoteReasons addObject:[[DownvoteReason alloc] initWithGUID:item[@"downvotereason_uuid"]
                                                                    andName:item[@"downvotereason_label"]]];
        }
        
        cache = downvoteReasons;
    }
    return cache;
}


#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - NSObject Overrides

@end
