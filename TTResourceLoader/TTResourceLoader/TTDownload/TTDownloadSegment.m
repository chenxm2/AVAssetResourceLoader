//
//  TTDownloadSegment.m
//  aaa
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import "TTDownloadSegment.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "TTCache.h"

#define kTTDownloadSegmentPath @"TTDownloadSegment"

@interface TTDownloadSegment ()
@property (nonatomic, assign) unsigned long long offset;
@property (nonatomic, assign) unsigned long long length;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) YYCache *yyCache;
@end

@implementation TTDownloadSegment

- (id)initWithURL:(NSURL *)url offset:(unsigned long long)offset length:(unsigned long long)length manager:(AFHTTPRequestOperationManager *)manager
{
    self = [super init];
    if (self)
    {
        self.url = url;
        self.offset = offset;
        self.length = length;
        self.manager = manager;
        self.yyCache = [TTCache cacheInstanceWithPath:[TTDownloadSegment downloadSegmentFullPath]];
    }
    return self;
}

- (AFHTTPRequestOperation *)generateOperation
{
    AFHTTPRequestOperation *operation = nil;
    
    __weak typeof(self)weakSelf = self;
    
    if (![self isDownloaded])
    {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", self.offset, self.offset + self.length - 1]  forHTTPHeaderField:@"Range"];
        

        
        operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.yyCache setObject:responseObject forKey:[strongSelf downloadSegmentFileDataKey] withBlock:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                   [strongSelf.delegate didSegmentFinished:strongSelf];
                });
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            NSLog(@"_createOperation Fail:%@", error);
        }];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.delegate didSegmentFinished:strongSelf];
        });
    }
    
    return operation;
}

- (BOOL)isDownloaded
{
    BOOL result = NO;
    if ([self.yyCache containsObjectForKey:[self downloadSegmentFileDataKey]])
    {
        result = YES;
    }
    
    return result;
}

- (NSData *)segmentData
{
    id data = [self.yyCache objectForKey:[self downloadSegmentFileDataKey]];
    if ([data isKindOfClass:[NSData class]])
    {
        return data;
    }
    
    return nil;
}

- (NSString *)downloadSegmentFileDataKey
{
    NSString *urlString = self.url.absoluteString;
    NSString *segmentFileInfoString = [NSString stringWithFormat:@"segmentFileData%llu,%llu", self.offset, self.length];
    
    NSString *resultString = [urlString stringByAppendingString:segmentFileInfoString];
    
    return resultString;
}

+ (NSString *)downloadSegmentFullPath
{
    NSString *documentPaht = [TTDownloadSegment documentPath];
    NSString *downloadSegmentFullPath = [documentPaht stringByAppendingPathComponent:kTTDownloadSegmentPath];
    
    return downloadSegmentFullPath;
}

+ (NSString *)documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths objectAtIndex:0];
    return docPath;
}
@end
