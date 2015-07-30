//
//  AmazonServices.m
//  Runway
//
//  Created by Roberto Cordon on 7/8/15.
//  Copyright (c) 2015 Roberto Cordon. All rights reserved.
//

#import "AmazonServices.h"
#import <AWSS3/AWSS3.h>

#define FULL_IMAGE_NAME(uuid)               [NSString stringWithFormat:@"%@_full.png", uuid]
#define THUMB_IMAGE_NAME(uuid)              [NSString stringWithFormat:@"%@_thumb.png", uuid]

#define AMAZON_BUCKET_NAME                  @"runway-s3-dev"

@implementation AmazonServices
#pragma mark - Getters/Setters

////////////////////////////////////////////////////////////////////////
//
// Public Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Public Functions
+ (BOOL)uploadFullImage:(UIImage *)fullImage
      andThumbnailImage:(UIImage *)thumbnailImage
               withUUID:(NSString *)uuid
{
    BOOL fullSuccess  = NO;
    BOOL thumbSuccess = NO;

    fullSuccess = [self uploadImage:fullImage withName:FULL_IMAGE_NAME(uuid)];
    if(fullSuccess) thumbSuccess = [self uploadImage:thumbnailImage withName:THUMB_IMAGE_NAME(uuid)];

    return (fullSuccess && thumbSuccess);
}

+ (UIImage *)downloadFullImageWithUUID:(NSString *)uuid
{
    return [self downloadImageWithName:FULL_IMAGE_NAME(uuid)];
}

+ (UIImage *)downloadThumbImageWithUUID:(NSString *)uuid
{
    return [self downloadImageWithName:THUMB_IMAGE_NAME(uuid)];
}

////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
////////////////////////////////////////////////////////////////////////
#pragma mark Helper Functions
+ (BOOL)uploadImage:(UIImage *)image
           withName:(NSString *)name
{
    __block BOOL success = NO;
    
    //create temporary path for image
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];

    //setup upload request
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.body = [NSURL fileURLWithPath:filePath];
    uploadRequest.key = name;
    uploadRequest.bucket = AMAZON_BUCKET_NAME;
    //uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend){NS Log(@"%i%%", (int)((double) totalBytesSent * 100 / totalBytesExpectedToSend));};

    //do tranfer. setup and use semaphores since this threads out.
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[AWSS3TransferManager defaultS3TransferManager] upload:uploadRequest] continueWithBlock:^id(AWSTask *task){
        //we won't even check task.error, since we assume success = NO, and we don't really care why it failed because we're not supporting cancelling or pausing.
        success = (task.result != nil);
        dispatch_semaphore_signal(semaphore);
        return nil;
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return success;
}

+ (UIImage *)downloadImageWithName:(NSString *)name
{
    __block UIImage *image;

    //determine temporary path for image
    NSURL *filePathURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]];

    //setup download request
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    downloadRequest.bucket = AMAZON_BUCKET_NAME;
    downloadRequest.key = name;
    downloadRequest.downloadingFileURL = filePathURL;
    
    //do tranfer. setup and use semaphores since this threads out.
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[AWSS3TransferManager defaultS3TransferManager] download:downloadRequest] continueWithBlock:^id(AWSTask *task) {
        if(!task.error){
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePathURL]];
        }
        dispatch_semaphore_signal(semaphore);
        return nil;
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return image;
}

#pragma mark - IBAction Handlers
#pragma mark Gesture Handlers
#pragma mark - Protocol Implementation
#pragma mark - NSObject Overrides

@end
