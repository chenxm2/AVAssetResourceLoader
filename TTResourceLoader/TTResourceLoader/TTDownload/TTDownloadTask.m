 //
//  TTDownloadTask.m
//
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import "TTDownloadTask.h"
#import "TTDownloadSegment.h"
#import "TTDownloadContentInfo.h"


const NSInteger kDefaultSegmentBytes = 1024 * 10; //100 K

@interface TTDownloadTask () <TTDownloadSegmentDelegate>
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) TTDownloadContentInfo *downloadContentInfo;
@property (nonatomic, strong) NSMutableArray *validDataRangeArray;
@property (nonatomic, strong) NSMutableArray *segmentArray;
@property (nonatomic, strong) NSMutableDictionary *segmentDictionary;
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
        self.validDataRangeArray = [NSMutableArray array];
        self.segmentArray = [[NSMutableArray alloc] init];
        self.segmentDictionary = [NSMutableDictionary dictionary];
    }
    
    return self;

}

- (void)startTask:(void (^)(BOOL success))successBlock;
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
    [request setHTTPMethod:@"HEAD"];
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self)weakSelf = self;
    NSURLSessionTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if ([response isKindOfClass:[NSHTTPURLResponse class]] && (((NSHTTPURLResponse *)response).statusCode == 200 || ((NSHTTPURLResponse *)response).statusCode == 206))
        {
            strongSelf.downloadContentInfo = [[TTDownloadContentInfo alloc] initWithResponse:(NSHTTPURLResponse *)response];
            [strongSelf createSegments];
        }
        else
        {
            successBlock(NO);
            NSLog(@"HEAD URL Fail:%@", error);
        }

        
    }];
    [dataTask resume];
}


- (void)createSegments
{
    NSUInteger segmentBytesSize = self.segmentBytesSize;
    
    if (!self.downloadContentInfo.byteRangeAccessSupported)
    {
        segmentBytesSize = self.downloadContentInfo.contentLength;
    }
    
    if (segmentBytesSize == 0)
    {
        segmentBytesSize = kDefaultSegmentBytes;
    }
    
    unsigned long long mod = self.downloadContentInfo.contentLength % segmentBytesSize;
    unsigned long long count = self.downloadContentInfo.contentLength / segmentBytesSize;
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
    TTDownloadSegment *segment = [[TTDownloadSegment alloc] initWithURL:url offset:offset length:length];
    segment.delegate = self;
    [self.segmentArray addObject:segment];
    NSString *key = [NSString stringWithFormat:@"%llu", segment.offset];
    [self.segmentDictionary setObject:segment forKey:key];
    
    [segment startDownloadIfNeed];
    
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
    for (; i < [self.validDataRangeArray count]; i++)
    {

        NSValue *value = [self.validDataRangeArray objectAtIndex:i];
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
    
    [self.validDataRangeArray insertObject:[NSValue valueWithRange:range] atIndex:insertIndex];
    
    NSLog(@"didSegmentFinished:%lu", (unsigned long)[self.validDataRangeArray count]);
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
    for (NSInteger i = 0; i < [self.validDataRangeArray count]; i++)
    {
        
        NSValue *value = [self.validDataRangeArray objectAtIndex:i];
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
@end
