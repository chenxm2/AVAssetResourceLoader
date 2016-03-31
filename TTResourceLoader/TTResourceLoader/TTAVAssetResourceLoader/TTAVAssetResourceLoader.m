//
//  TTAVAssetResourceLoader.m
//  TTResourceLoader
//
//  Created by xianmingchen on 16/3/29.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import "TTAVAssetResourceLoader.h"
#import "TTDownloadTask.h"

@interface TTAVAssetResourceLoader () <TTDownloadTaskDelegate>
@property (nonatomic, strong) NSMutableArray *pendingRequests;
@property (nonatomic, strong) NSMutableArray *waitingRequest;
@property (nonatomic, strong) TTDownloadTask *downloadTask;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation TTAVAssetResourceLoader

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.pendingRequests = [NSMutableArray array];
        self.waitingRequest = [NSMutableArray array];
    }
    
    return self;
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    if (contentInformationRequest == nil || self.downloadTask.contentInformation == nil)
    {
        return;
    }
    
    NSString *mimeType = [self.downloadTask.contentInformation contentType];
    
    
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = mimeType;
    contentInformationRequest.contentLength = self.downloadTask.contentInformation.contentLength;
}

- (void)respondWithDataForRequest:(AVAssetResourceLoadingRequest *)loadingReauest completedBlock:(void (^)(BOOL isRespondFully, AVAssetResourceLoadingRequest *loadingReauest, unsigned long long actullyLength))completedBlock
{
    __block BOOL didRespondFully = NO;
    
//    static unsigned long long currentMaxStartOffset = 0;
    
    AVAssetResourceLoadingDataRequest *dataRequest = loadingReauest.dataRequest;
    
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0)
    {
        startOffset = dataRequest.currentOffset;
    }
    
    [self.downloadTask dataWithOffset:startOffset length:dataRequest.requestedLength completedBlock:^(NSData *data, unsigned long long offset, unsigned long long actullyLength) {
        if (actullyLength > 0 && data)
        {
            [dataRequest respondWithData:data];
            
            NSLog(@"respondWithDataForRequest:startOffet:%lld, actullyLength:%llu, dataLength:%lu, offset:%llu", startOffset, actullyLength, (unsigned long)[data length], offset);
            
            didRespondFully = ((actullyLength + startOffset) >= dataRequest.requestedLength + dataRequest.requestedOffset);
            if (completedBlock)
            {
                completedBlock(didRespondFully, loadingReauest, actullyLength);
            }
        }
        else
        {
            if (completedBlock)
            {
                completedBlock(didRespondFully, loadingReauest, actullyLength);
            }

        }
        
    }];
    
}
    
- (void)startTimer
{
    self.timer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(_timerFire:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)_timerFire:(NSTimer *)timer
{
    if ([self.waitingRequest count] > 0)
    {
        [self processWaitingRequests];
    }
    else
    {
        [self stopTimer];
    }
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

    
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"shouldWaitForLoadingOfRequestedResource:%@", loadingRequest);
    if (self.downloadTask == nil)
    {
        NSURL *interceptedURL = [loadingRequest.request URL];
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:interceptedURL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = @"http";
        
        self.downloadTask = [[TTDownloadTask alloc] initWithURL:[actualURLComponents URL]];
        self.downloadTask.delegate = self;
        [self.downloadTask startTask:^(BOOL success) {
            
        }];
    }
    
    if (![self.waitingRequest containsObject:loadingRequest]) {
        [self.waitingRequest addObject:loadingRequest];
    }
    
    if (self.timer == nil)
    {
        [self startTimer];
    }
    
    return YES;
}
    
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.pendingRequests removeObject:loadingRequest];
    [self.waitingRequest removeObject:loadingRequest];
        
    NSLog(@"didCancelLoadingRequest:%@", loadingRequest);
        
}

- (void)processWaitingRequests
{
    NSLog(@"processPendingRequests being");
    __weak typeof(self)weakSelf = self;
    
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.waitingRequest)
    {
        if ([self.pendingRequests containsObject:loadingRequest])
        {
            continue;
        }
        else
        {
            [self.pendingRequests addObject:loadingRequest];
        }
        
        [self fillInContentInformation:loadingRequest.contentInformationRequest];
        [self respondWithDataForRequest:loadingRequest completedBlock:^(BOOL isRespondFully, AVAssetResourceLoadingRequest *loadingReauest, unsigned long long actullyLength) {
            if (isRespondFully)
            {
                NSLog(@"finished loadingRequest :%@", loadingReauest);
                [loadingRequest finishLoading];
                __strong typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf.pendingRequests removeObject:loadingRequest];
            }
            else
            {
                [self.pendingRequests removeObject:loadingReauest];
                [self.waitingRequest addObject:loadingReauest];
            }
        }];
        
    }
    
    [self.waitingRequest removeObjectsInArray:self.pendingRequests];
    
    NSLog(@"processPendingRequests end");
}


#pragma mark -
- (void)didRLDownloadTaskDataRefresh:(TTDownloadTask *)downloadTask
{
    [self processWaitingRequests];
}


- (void)didRLDownloadTaskDataFinished:(TTDownloadTask *)downloadTask
{
}

@end
