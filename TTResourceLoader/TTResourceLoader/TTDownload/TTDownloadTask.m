 //
//  TTDownloadTask.m
//
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import "TTDownloadTask.h"
#import "AFHTTPRequestOperationManager.h"
#import "TTDownloadSegment.h"
#import "AFURLResponseSerialization.h"

const NSInteger kDefaultSegmentBytes = 1024 * 100; //100 K

@implementation RLContentInformation

- (instancetype)initWithResponse:(NSURLResponse *)response
{
    self = [super init];
    if (self) {
        NSString *mimeType = [response MIMEType];
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
        
        _contentType = CFBridgingRelease(contentType);
        _contentLength = response.expectedContentLength;
        _validDataRangeArray = [[NSMutableArray alloc] init];
        _validDataRangeArray = [[NSMutableArray alloc] init];
    }
    return self;
}
@end

@interface TTDownloadTask () <TTDownloadSegmentDelegate>
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) AFHTTPRequestOperationManager *httpRequestManager;
@property (nonatomic, strong) RLContentInformation *contentInformation;
@property (nonatomic, strong) NSMutableArray *segmentArray;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableData *data;

@property (nonatomic, assign) NSInteger segmentCount;
@end

@implementation TTDownloadTask

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    
    if (self)
    {
        _url = url;
        self.httpRequestManager = [[AFHTTPRequestOperationManager alloc] init];
        self.httpRequestManager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
        self.httpRequestManager.requestSerializer = [[AFHTTPRequestSerializer alloc] init];
        self.httpRequestManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        self.segmentArray = [[NSMutableArray alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 3;
    }
    
    return self;
}

- (void)startTask:(void (^)(BOOL success))successBlock;
{
    [self.httpRequestManager HEAD:[self.url absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation) {
        self.contentInformation = [[RLContentInformation alloc] initWithResponse:operation.response];
        
        _data = [NSMutableData dataWithLength:self.contentInformation.contentLength];
        
        [self createSegments];
        if (successBlock)
        {
            successBlock(YES);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      
        successBlock(NO);
        NSLog(@"HEAD URL Fail:%@", error);
    }];
}


- (void)createSegments
{
    unsigned long long mod = self.contentInformation.contentLength % kDefaultSegmentBytes;
    unsigned long long count = self.contentInformation.contentLength / kDefaultSegmentBytes;
    unsigned long long currentOffset = 0;
    
    self.segmentCount = count;
    
    NSLog(@"createSegments%llu", count);
    
    for (NSInteger i = 0; i < count; i++)
    {
        if (![self isHadCacheWithOffest:currentOffset])
        {
            TTDownloadSegment *segment = [[TTDownloadSegment alloc] initWithURL:self.url offset:currentOffset length:kDefaultSegmentBytes manager:self.httpRequestManager];
            
            segment.delegate = self;
            [self.segmentArray addObject:segment];
            [self.operationQueue addOperation:segment.operation];
        }
        
        currentOffset += kDefaultSegmentBytes;
    }
    
    if (mod > 0 && ![self isHadCacheWithOffest:currentOffset])
    {
        self.segmentCount ++;
        
         TTDownloadSegment *segment = [[TTDownloadSegment alloc] initWithURL:self.url offset:currentOffset length:mod manager:self.httpRequestManager];
        
        segment.delegate = self;
        [self.segmentArray addObject:segment];
        [self.operationQueue addOperation:segment.operation];
    }
}

- (BOOL)isHadCacheWithOffest:(unsigned long long)offset
{
    BOOL result = NO;
    
    for (NSValue *value in self.contentInformation.validDataRangeArray)
    {
        NSRange range = [value rangeValue];
        if  (range.location == offset)
        {
            result = YES;
            break;
        }
    }
        
    return result;
}

#pragma mark - RLDownloadSegmentDelegate

- (void)didSegmentFinished:(TTDownloadSegment *)segment
{
    
    static int count = 0;
    count ++;
    
    NSRange range = NSMakeRange(segment.offset, segment.length);
    [self.data replaceBytesInRange:range withBytes:[segment.operation.responseData bytes]];
    
    NSLog(@"didSegmentFinished %@", [NSValue valueWithRange:range]);
    
    
    long insertIndex = 0;
    BOOL findIndex = NO;
    NSInteger i = 0;
    for (; i < [self.contentInformation.validDataRangeArray count]; i++)
    {

        NSValue *value = [self.contentInformation.validDataRangeArray objectAtIndex:i];
        NSRange range = [value rangeValue];
        
        if (segment.offset < range.location)
        {
            insertIndex = i;
            findIndex = YES;
            break;
        }
    }
    
    if (!findIndex)
    {
        insertIndex = i;
    }
    
    
    [self.contentInformation.validDataRangeArray insertObject:[NSValue valueWithRange:range] atIndex:insertIndex];
    
    NSLog(@"didSegmentFinished:%lu", (unsigned long)[self.contentInformation.validDataRangeArray count]);
    NSLog(@"didSegmentFinished offset:%llu, length:%llu, destOffset:%llu", segment.offset, segment.length, segment.offset + segment.length);
    
    
    [self.delegate didRLDownloadTaskDataRefresh:self];
    
    if (count == self.segmentCount)
    {
        NSLog(@"%@", self.contentInformation.validDataRangeArray);
        
        
        NSArray *pathcaches=NSSearchPathForDirectoriesInDomains(NSCachesDirectory
                                                                , NSUserDomainMask
                                                                , YES);
        NSString* cacheDirectory  = [pathcaches objectAtIndex:0];
        NSString* filePath = [cacheDirectory stringByAppendingPathComponent:@"cachevideo.mp4"];
        
        NSLog(@"%@", filePath);
        

        
        
        NSMutableData *finishedData = [NSMutableData data];
        for (NSInteger i = 0; i < count; i++)
        {
            TTDownloadSegment *segment = [self.segmentArray objectAtIndex:i];
            [finishedData appendData:segment.operation.responseData];
        }
    }
    
}

- (NSData *)dataWithOffset:(unsigned long long)offset length:(unsigned long long)length actuallyReadLength:(unsigned long long *)actullyLength
{
    NSMutableData *result = [[NSMutableData alloc] init];
    *actullyLength = 0;
    
    NSRange compareRange = NSMakeRange(offset, length);
    
    NSRange mergeRange = NSMakeRange(0, 0);
    BOOL hasData = NO;

    for (NSInteger i = 0; i < [self.contentInformation.validDataRangeArray count]; i++)
    {
        
        NSValue *value = [self.contentInformation.validDataRangeArray objectAtIndex:i];
        NSRange range = [value rangeValue];
        
        NSRange intersectionRange = NSIntersectionRange(range, compareRange);
        
        if (intersectionRange.length != 0 && intersectionRange.location == compareRange.location)
        {
            hasData = YES;
            if (mergeRange.length == 0)
            {
                mergeRange = range;
            }
        }
        else if (hasData && intersectionRange.length != 0)
        {
            if (mergeRange.location + mergeRange.length == range.location)
            {
                mergeRange.length += range.length;
            }
        }
    }

    NSLog(@"mergeRange:%@", [NSValue valueWithRange:mergeRange]);
    
    if (hasData)
    {
        NSRange actullyReadRange = NSMakeRange(0, 0);
        NSUInteger startOffset = compareRange.location;
        actullyReadRange.location = startOffset;
        
        
        NSUInteger minLength = MIN(length, mergeRange.location + mergeRange.length - startOffset);
        
        actullyReadRange.length = minLength;
        *actullyLength = (unsigned long long)minLength;
        
        [result appendData:[self.data subdataWithRange:actullyReadRange]]; //要读文件以后，并cahe起来
        
    }
    return result;
}
@end
