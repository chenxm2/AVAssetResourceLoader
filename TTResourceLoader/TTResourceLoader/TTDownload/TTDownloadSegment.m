//
//  TTDownloadSegment.m
//  aaa
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import "TTDownloadSegment.h"

#import "TTCache.h"

#define kTTDownloadSegmentPath @"TTDownloadSegment"

@interface TTDownloadSegment ()
@property (nonatomic, assign) unsigned long long offset;
@property (nonatomic, assign) unsigned long long length;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) YYCache *yyCache;



@end

@implementation TTDownloadSegment

- (id)initWithURL:(NSURL *)url offset:(unsigned long long)offset length:(unsigned long long)length
{
    self = [super init];
    if (self)
    {
        self.url = url;
        self.offset = offset;
        self.length = length;
        self.yyCache = [TTCache cacheInstanceWithPath:[TTDownloadSegment downloadSegmentFullPath]];
    }
    return self;
}

- (void)startDownloadIfNeed
{
    if (![self isDownloaded])
    {
        [self startDownload];
    }
    else
    {
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.delegate didSegmentFinished:strongSelf];
        });
    }
}

- (void)startDownload
{
    __weak typeof(self)weakSelf = self;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", self.offset, self.offset + self.length - 1]  forHTTPHeaderField:@"Range"];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        if ([data length] != strongSelf.length)
        {
            NSLog(@"XXXX");
        }
        
        [strongSelf.yyCache setObject:data forKey:[strongSelf downloadSegmentFileDataKey] withBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf.delegate didSegmentFinished:strongSelf];
            });
        }];
        
    }];
    
    [dataTask resume];
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
    
    
    if (data && [data length] != self.length)
    {
        NSLog(@"segmentData Exeption");
    }
    
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
