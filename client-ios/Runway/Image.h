//
//  Image.h
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "Tag.h"

@class FacebookPhoto;
@interface Image : NSObject

@property (nonatomic, strong) NSString *GUID;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, readonly) NSString *thumbnailImageURL;
@property (nonatomic, strong, readonly) NSString *fullImageURL;
@property (nonatomic, strong, readonly) UIImage *thumbnailImage;
@property (nonatomic, strong, readonly) UIImage *fullImage;
@property (nonatomic, readonly) BOOL thumbnailImageAvailable;
@property (nonatomic, readonly) BOOL fullImageAvailable;
@property (nonatomic, readonly) int upvotes;
@property (nonatomic, readonly) int downvotes;
@property (nonatomic, readonly) int totalKarma;                     //calculated from all tags(upvote - downvote)
@property (nonatomic, readonly) int totalPercentUpvoted;            //calculated and rounded from all tags(upvote/(upvote + downvote))
@property (nonatomic, strong, readonly) NSMutableArray *tags;
@property (nonatomic) BOOL iOwnIt;

- (Image *)initWithGUID:(NSString *)GUID
                  title:(NSString *)title
      thumbnailImageURL:(NSString *)thumbnailImageURL
           fullImageURL:(NSString *)fullImageURL
            andTagArray:(NSMutableArray *)tags                      //can be nil, will be init to empty
                 iOwnIt:(BOOL)iOwnIt;

- (Image *)initWithGUID:(NSString *)GUID
                  title:(NSString *)title
         thumbnailImage:(UIImage *)thumbnailImage
              fullImage:(UIImage *)fullImage
            andTagArray:(NSMutableArray *)tags                      //can be nil, will be init to empty
                 iOwnIt:(BOOL)iOwnIt;

- (Image *)initWithGUID:(NSString *)GUID
                  title:(NSString *)title
          facebookPhoto:(FacebookPhoto *)photo
            andTagArray:(NSMutableArray *)tags                      //can be nil, will be init to empty
                 iOwnIt:(BOOL)iOwnIt;


- (void)addTag:(Tag *)tag;
- (void)deleteTag:(Tag *)tag;
- (void)deleteSelf;

- (void)saveEditChanges;                                            //if GUID is nil, it will be created as a new one, and the property will be set with what's returned
- (void)saveVotes;                                                  //save upvotes
@end
