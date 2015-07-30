//
//  Image.m
//  Runway
//
//  Created by Roberto Cordon on 5/22/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "Image.h"
#import "FacebookPhoto.h"

#import "AmazonServices.h"
#import "RunwayServices.h"

#define THUMB_CACHE_DIR     @"thumbs"
#define FULL_CACHE_DIR      @"full"

#define MAX_CACHED_THUMBS   100
#define MAX_CACHED_FULLS    20

@interface Image()
@property (nonatomic, strong) FacebookPhoto *fbPhoto;

@property (nonatomic) BOOL imageKarmaDataValid;
@property (nonatomic) int upvotesCache;
@property (nonatomic) int downvotesCache;
@end

@implementation Image
@synthesize thumbnailImage = _thumbnailImage;
@synthesize fullImage = _fullImage;

////////////////////////////////////////////////////////////////////////
//
// Getters/Setters
//
////////////////////////////////////////////////////////////////////////
#pragma mark - Getters/Setters
- (UIImage *)thumbnailImage
{
    
    if(!_thumbnailImage){                                                                                                       //if we don't have it yet
        UIImage *cachedImage = [Image thumbnailCacheWithGUID:self.GUID];                                                            //try to load from cached directory
        if(cachedImage){                                                                                                            //if it's there , set it
            _thumbnailImage = cachedImage;
        }else{                                                                                                                      //otherwise
            if(_thumbnailImageURL){                                                                                             //if we have the URL, load it
                UIImage *tmpImage = [AmazonServices downloadThumbImageWithUUID:_thumbnailImageURL];
                if(tmpImage){
                    _thumbnailImage = tmpImage;
                    [Image saveThumbnailCacheForImage:_thumbnailImage withGUID:self.GUID];
                }
            }else if(self.fbPhoto){                                                                                             //if we have the FB data, load that instead
                if(self.fbPhoto.photoThumbnailToUploadCache){
                    _thumbnailImage = self.fbPhoto.photoThumbnailToUploadCache;
                }else{
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    [self.fbPhoto getPhotoThumbnailsWithCompletionBlock:^{
                        _thumbnailImage = self.fbPhoto.photoThumbnailToUploadCache;
                        dispatch_semaphore_signal(semaphore);                                                                   //release the semaphore
                    }];
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);                                                  //this here will wait until we call dispatch_semaphore_signal on semaphore
                }
            }
        }
    }
    
    return _thumbnailImage;
}

- (UIImage *)fullImage
{
    if(!_fullImage){
        UIImage *cachedImage = [Image fullCacheWithGUID:self.GUID];
        if(cachedImage){
            _fullImage = cachedImage;
        }else{
            if(_fullImageURL){
                
                UIImage *tmpImage = [AmazonServices downloadFullImageWithUUID:_fullImageURL];
                if(tmpImage){
                    _fullImage = tmpImage;
                    [Image saveFullCacheForImage:_fullImage withGUID:self.GUID];
                }
            }else if(self.fbPhoto){                                                                                             //if we have the FB data, load that instead
                if(self.fbPhoto.photoCache){
                    _fullImage = self.fbPhoto.photoCache;
                }else{
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    [self.fbPhoto getPhotoWithCompletionBlock:^{
                        _fullImage = self.fbPhoto.photoCache;
                        dispatch_semaphore_signal(semaphore);                                                                   //release the semaphore
                    }];
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);                                                  //this here will wait until we call dispatch_semaphore_signal on semaphore
                }
            }
        }
    }
    return _fullImage;
}

- (BOOL)thumbnailImageAvailable
{
    return (_thumbnailImage != nil);
}

- (BOOL)fullImageAvailable
{
    return (_fullImage != nil);
}

- (void)setTags:(NSMutableArray *)tags
{
    _tags = tags;
    
    self.imageKarmaDataValid = NO;
}

- (int)upvotes
{
    return self.upvotesCache;
}

- (int)downvotes
{
    return self.downvotesCache;
}

- (int)totalKarma
{
    return (self.upvotesCache - self.downvotesCache);
}

- (int)totalPercentUpvoted
{
    return ((self.upvotesCache * 100)/(self.upvotesCache + self.downvotesCache));
}

- (int)upvotesCache
{
    [self updateImageKarmaData];
    return _upvotesCache;
}

- (int)downvotesCache
{
    [self updateImageKarmaData];
    return _downvotesCache;
}

- (void)updateImageKarmaData
{
    if(!self.imageKarmaDataValid){
        _upvotesCache = _downvotesCache = 0;
        for(Tag *tag in self.tags){
            _upvotesCache+= tag.upvotes;
            _downvotesCache+= tag.downvotes;
        }
    }
}

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
- (Image *)initWithGUID:(NSString *)GUID
                  title:(NSString *)title
      thumbnailImageURL:(NSString *)thumbnailImageURL
           fullImageURL:(NSString *)fullImageURL
            andTagArray:(NSMutableArray *)tags                      //can be nil, will be init to empty
                 iOwnIt:(BOOL)iOwnIt
{
    if(self = [super init]){
        self.GUID = GUID;
        self.title = title;
        _thumbnailImageURL = thumbnailImageURL;
        _fullImageURL = fullImageURL;
        _tags = tags ? tags : [@[] mutableCopy];
        self.iOwnIt = iOwnIt;
    }
    return self;
}

- (Image *)initWithGUID:(NSString *)GUID
                  title:(NSString *)title
         thumbnailImage:(UIImage *)thumbnailImage
              fullImage:(UIImage *)fullImage
            andTagArray:(NSMutableArray *)tags                      //can be nil, will be init to empty
                 iOwnIt:(BOOL)iOwnIt
{
    if(self = [super init]){
        self.GUID = GUID;
        self.title = title;
        _thumbnailImage = thumbnailImage;
        _fullImage = fullImage;
        _tags = tags ? tags : [@[] mutableCopy];
        self.iOwnIt = iOwnIt;
    }
    return self;
}

- (Image *)initWithGUID:(NSString *)GUID
                  title:(NSString *)title
          facebookPhoto:(FacebookPhoto *)photo
            andTagArray:(NSMutableArray *)tags                      //can be nil, will be init to empty
                 iOwnIt:(BOOL)iOwnIt
{
    if(self = [super init]){
        self.GUID = GUID;
        self.title = title;
        self.fbPhoto = photo;
        _tags = tags ? tags : [@[] mutableCopy];
        self.iOwnIt = iOwnIt;
    }
    return self;
}

- (void)addTag:(Tag *)tag
{
    tag.parentImageGUID = self.GUID;
    [self.tags addObject:tag];

    self.imageKarmaDataValid = NO;
}

- (void)deleteTag:(Tag *)tag
{
    [self.tags removeObject:tag];

    if(tag.GUID.length){
        dispatch_async(dispatch_queue_create("delete tag", NULL), ^{
            [RunwayServices deleteTagWithGUID:tag.GUID];
        });
    }

    self.imageKarmaDataValid = NO;
}

- (void)deleteSelf
{
    if(self.GUID.length){
        [RunwayServices deleteImageWithGUID:self.GUID];
    }
}

- (void)saveEditChanges
{
    if(self.GUID.length){
        //if it's new, just save all the tags
        for(Tag *t in self.tags){
            [t saveEditChanges];
        }
    }else{
        [RunwayServices saveNewImage:self];
    }
}

- (void)saveVotes
{
    for(Tag *tag in self.tags){
        [tag saveVoteIfNecessary];
    }
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
+ (NSString *)pathToCachedThumbnailsDirectory
{
    return [self pathToCachedSubDirectory:THUMB_CACHE_DIR];
}

+ (NSString *)pathToCachedFullDirectory
{
    return [self pathToCachedSubDirectory:FULL_CACHE_DIR];
}

+ (UIImage *)thumbnailCacheWithGUID:(NSString *)GUID
{
    UIImage *image = nil;
    if(GUID.length){
        NSString *pathToImage = [[self pathToCachedThumbnailsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", GUID]];
        image = [self imageAtPath:pathToImage];
    }
    return image;
}

+ (UIImage *)fullCacheWithGUID:(NSString *)GUID
{
    UIImage *image = nil;
    if(GUID.length){
        NSString *pathToImage = [[self pathToCachedFullDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", GUID]];
        image = [self imageAtPath:pathToImage];
    }
    return image;
}

+ (void)saveThumbnailCacheForImage:(UIImage *)image
                          withGUID:(NSString *)GUID
{
    if(GUID.length){
        NSString *pathToImage = [[self pathToCachedThumbnailsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", GUID]];
        [self saveImage:image toPath:pathToImage];
    }
}

+ (void)saveFullCacheForImage:(UIImage *)image
                     withGUID:(NSString *)GUID
{
    if(GUID.length){
        NSString *pathToImage = [[self pathToCachedFullDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", GUID]];
        [self saveImage:image toPath:pathToImage];
    }
}

+ (NSString *)pathToCachedSubDirectory:(NSString *)subDirectory
{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *subPath = [cachePath stringByAppendingPathComponent:subDirectory];
    
    //create if doesn't exist
    if(![[NSFileManager defaultManager] fileExistsAtPath:subPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:subPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return subPath;
}

+ (UIImage *)imageAtPath:(NSString *)pathToImage
{
    UIImage *image = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:pathToImage]){
        image = [UIImage imageWithContentsOfFile:pathToImage];
    }
    return image;
}

+ (void)saveImage:(UIImage *)image
           toPath:(NSString *)pathToImage
{
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:pathToImage atomically:YES];
    
    [self enforceCacheLimit];
}

+ (void)enforceCacheLimit
{
    //enforce thumb max
    while([[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self pathToCachedThumbnailsDirectory] error:nil].count > MAX_CACHED_THUMBS){
        //get oldest file and delete it
        NSString *oldestPath = [self lastAccessedFileInDirectory:[self pathToCachedThumbnailsDirectory]];
        if(oldestPath){
            [[NSFileManager defaultManager] removeItemAtPath:oldestPath error:nil];
        }
    }
    
    //enforce full max
    while([[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self pathToCachedFullDirectory] error:nil].count > MAX_CACHED_FULLS){
        //get oldest file and delete it
        NSString *oldestPath = [self lastAccessedFileInDirectory:[self pathToCachedFullDirectory]];
        if(oldestPath){
            [[NSFileManager defaultManager] removeItemAtPath:oldestPath error:nil];
        }
    }
    
}

+ (NSString *)lastAccessedFileInDirectory:(NSString *)path
{
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSArray *pngFiles = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.png'"]];

    NSDate *oldest = [NSDate date];
    NSString *oldestFileName = nil;
    for(NSString *fileName in pngFiles){
        NSString *photoPath = [path stringByAppendingPathComponent:fileName];
        NSDate *modify = [[[NSFileManager defaultManager] attributesOfItemAtPath:photoPath error:nil] objectForKey:NSFileModificationDate];
        
        if([modify compare:oldest] == NSOrderedAscending){
            oldestFileName = [NSString stringWithString:photoPath];
            oldest = modify;
        }
    }

    return oldestFileName;
}

#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - UIViewController Overrides

@end
