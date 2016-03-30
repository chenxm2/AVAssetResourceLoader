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

@implementation TTContentInformation

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response
{
    self = [super init];
    if (self) {
        NSString *mimeType = [response MIMEType];
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
        
        _contentType = CFBridgingRelease(contentType);
        _contentLength = response.expectedContentLength;
        _validDataRangeArray = [NSMutableArray array];
        
        NSDictionary *headField = [response allHeaderFields];
        id value = [headField objectForKey:@"Accept-Ranges"];
        if ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"bytes"])
        {
            _byteRangeAccessSupported = YES;
        }
        else
        {
            _byteRangeAccessSupported = NO;
        }
    }
    
    return self;
}
@end

@interface TTDownloadTask () <TTDownloadSegmentDelegate>
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) AFHTTPRequestOperationManager *httpRequestManager;
@property (nonatomic, strong) TTContentInformation *contentInformation;
@property (nonatomic, strong) NSMutableArray *segmentArray;
@property (nonatomic, strong) NSMutableDictionary *segmentDictionary;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation TTDownloadTask

- (id)initWithURL:(NSURL *)url
{
    return [self initWithURL:url downloadSegmentBytesSize:kDefaultSegmentBytes];
}

- (id)initWithURL:(NSURL *)url downloadSegmentBytesSize:(NSUInteger)size
{
    self = [super init];
    if (self)
    {
        _url = url;
        _segmentBytesSize = size;
        self.httpRequestManager = [[AFHTTPRequestOperationManager alloc] init];
        self.httpRequestManager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
        self.httpRequestManager.requestSerializer = [[AFHTTPRequestSerializer alloc] init];
        self.httpRequestManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        self.segmentArray = [[NSMutableArray alloc] init];
        self.segmentDictionary = [NSMutableDictionary dictionary];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 3;
    }
    
    return self;

}

- (void)startTask:(void (^)(BOOL success))successBlock;
{
    [self.httpRequestManager HEAD:[self.url absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation) {
        self.contentInformation = [[TTContentInformation alloc] initWithResponse:operation.response];
        
//        _data = [NSMutableData dataWithLength:self.contentInformation.contentLength];
        
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
    NSUInteger segmentBytesSize = self.segmentBytesSize;
    
    if (!self.contentInformation.byteRangeAccessSupported)
    {
        segmentBytesSize = self.contentInformation.contentLength;
    }
    
    if (segmentBytesSize == 0)
    {
        segmentBytesSize = kDefaultSegmentBytes;
    }
    
    unsigned long long mod = self.contentInformation.contentLength % segmentBytesSize;
    unsigned long long count = self.contentInformation.contentLength / segmentBytesSize;
    unsigned long long currentOffset = 0;
    
    NSLog(@"createSegments%llu", count);
    
    for (NSInteger i = 0; i < count; i++)
    {
        [self createSegmentWithURL:self.url offset:currentOffset length:segmentBytesSize];
        currentOffset += segmentBytesSize;
    }
    
    if (mod > 0)
    {
        [self createSegmentWithURL:self.url offset:currentOffset length:mod];
    }
}

- (void)createSegmentWithURL:(NSURL *)url offset:(unsigned long long)offset length:(unsigned long long)length
{
    TTDownloadSegment *segment = [[TTDownloadSegment alloc] initWithURL:url offset:offset length:length manager:self.httpRequestManager];
    segment.delegate = self;
    [self.segmentArray addObject:segment];
    NSString *key = [NSString stringWithFormat:@"%llu", segment.offset];
    [self.segmentDictionary setObject:segment forKey:key];
    
    AFHTTPRequestOperation *operation = [segment generateOperation];
    if (operation)
    {
        [self.operationQueue addOperation:operation];
    }
}

#pragma mark - RLDownloadSegmentDelegate

- (void)didSegmentFinished:(TTDownloadSegment *)segment
{
    static int count = 0;
    count++;
    
    NSRange range = NSMakeRange(segment.offset, segment.length);
    
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
}

- (void)dataWithOffset:(unsigned long long)offset length:(unsigned long long)length completedBlock:(void (^) (NSData *data, unsigned long long offset,  unsigned long long actullyLength))completeBlock
{
    unsigned long long actullyLength = 0;
    
    NSRange compareRange = NSMakeRange(offset, length);
    NSRange mergeRange = NSMakeRange(0, 0);
    
    NSMutableArray *validSegments = [NSMutableArray array];
    
    BOOL hasData = NO;
    for (NSInteger i = 0; i < [self.contentInformation.validDataRangeArray count]; i++)
    {
        
        NSValue *value = [self.contentInformation.validDataRangeArray objectAtIndex:i];
        NSRange range = [value rangeValue];
        
        NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)range.location];
        
        NSRange intersectionRange = NSIntersectionRange(range, compareRange);
        //有交集，且location等于请求的offest
        if (intersectionRange.length != 0 && intersectionRange.location == compareRange.location)
        {
            hasData = YES;
            if (mergeRange.length == 0)
            {
                mergeRange = range;
                [validSegments addObject:[self.segmentDictionary objectForKey:key]];
            }
        }
        else if (hasData && intersectionRange.length != 0)
        {
            //如果下一个也有交集，那么判断这两个有效的range是否是连在一起的，是的话就继续加上长度
            if (mergeRange.location + mergeRange.length == range.location)
            {
                [validSegments addObject:[self.segmentDictionary objectForKey:key]];
                mergeRange.length += range.length;
            }
        }
    }
    
    NSLog(@"mergeRange:%@", [NSValue valueWithRange:mergeRange]);
    if (hasData)
    {
        NSRange actullyReadRange = NSMakeRange(0, 0);
        NSUInteger startOffset = offset;
        actullyReadRange.location = startOffset;
        //返回实际要返回的大小
        NSUInteger minLength = MIN(length, mergeRange.location + mergeRange.length - startOffset);
        actullyReadRange.length = minLength;
        [self dataWithValidSegments:validSegments actullyReadRange:actullyReadRange completedBlock:completeBlock];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock)
            {
                completeBlock(nil, offset, actullyLength);
            }
        });
    }
}

- (void)dataWithValidSegments:(NSArray *)validSegments actullyReadRange:(NSRange)actullyReadRange completedBlock:(void (^) (NSData *data, unsigned long long offset,  unsigned long long actullyLength))completeBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *resultData = nil;
        NSMutableData *tmpData = [NSMutableData data];
        
        unsigned long long tmpDataOffset = 0;
        unsigned long long tmpDataLength = 0;
        
        for (NSUInteger i = 0; i < [validSegments count]; i++)
        {
            TTDownloadSegment *segment = [validSegments objectAtIndex:i];
            NSData *data = [segment segmentData];
            [tmpData appendData:data];
            
            if (i == 0)
            {
                tmpDataOffset = segment.offset;
            }
            tmpDataLength += [data length];
        }
        
        unsigned long long cutLocation = actullyReadRange.location - tmpDataOffset;
        
        if (cutLocation + actullyReadRange.length <= [tmpData length])
        {
            resultData = [tmpData subdataWithRange:NSMakeRange(cutLocation, actullyReadRange.length)];
        }
        else
        {
            NSLog(@"dataWithOffset exeption");
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock)
            {
                completeBlock(resultData, actullyReadRange.location, actullyReadRange.length);
            }
        });
    });
}

//- (NSData *)dataWithOffset:(unsigned long long)offset length:(unsigned long long)length actuallyReadLength:(unsigned long long *)actullyLength
//{
//    NSMutableData *result = [[NSMutableData alloc] init];
//    *actullyLength = 0;
//    
//    NSRange compareRange = NSMakeRange(offset, length);
//    
//    NSRange mergeRange = NSMakeRange(0, 0);
//    BOOL hasData = NO;
//
//    for (NSInteger i = 0; i < [self.contentInformation.validDataRangeArray count]; i++)
//    {
//        
//        NSValue *value = [self.contentInformation.validDataRangeArray objectAtIndex:i];
//        NSRange range = [value rangeValue];
//        
//        NSRange intersectionRange = NSIntersectionRange(range, compareRange);
//        //有交集，且location等于请求的offest
//        if (intersectionRange.length != 0 && intersectionRange.location == compareRange.location)
//        {
//            hasData = YES;
//            if (mergeRange.length == 0)
//            {
//                mergeRange = range;
//            }
//        }
//        else if (hasData && intersectionRange.length != 0)
//        {
//            //如果下一个也有交集，那么判断这两个有效的range是否是连在一起的，是的话就继续加上长度
//            if (mergeRange.location + mergeRange.length == range.location)
//            {
//                mergeRange.length += range.length;
//            }
//        }
//    }
//
//    NSLog(@"mergeRange:%@", [NSValue valueWithRange:mergeRange]);
//    
//    if (hasData)
//    {
//        NSRange actullyReadRange = NSMakeRange(0, 0);
//        NSUInteger startOffset = compareRange.location;
//        actullyReadRange.location = startOffset;
//        
//        //返回实际要返回的大小
//        NSUInteger minLength = MIN(length, mergeRange.location + mergeRange.length - startOffset);
//        
//        actullyReadRange.length = minLength;
//        *actullyLength = (unsigned long long)minLength;
//        
//    }
//    return result;
//}
@end
