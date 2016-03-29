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
@property (nonatomic, strong) TTDownloadTask *downloadTask;

@end

@implementation TTAVAssetResourceLoader

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.pendingRequests = [NSMutableArray array];
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
    
- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    static unsigned long long allrespondLeng = 0;
    
    BOOL didRespondFully = NO;
    
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0)
    {
        startOffset = dataRequest.currentOffset;
    }
    
    unsigned long long actuallyLenngth = 0;
    NSData *data = [self.downloadTask dataWithOffset:startOffset length:dataRequest.requestedLength actuallyReadLength:&actuallyLenngth];
    

    
    allrespondLeng += actuallyLenngth;
    
    if (actuallyLenngth != 0)
    {
        [dataRequest respondWithData:data];
        didRespondFully = ((actuallyLenngth + startOffset) >= dataRequest.requestedLength);
        
    }
    
    return didRespondFully;
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
    
    [self.pendingRequests addObject:loadingRequest];
    
    return YES;
}
    
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.pendingRequests removeObject:loadingRequest];
        
    NSLog(@"didCancelLoadingRequest:%@", loadingRequest);
        
}

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    
    NSLog(@"processPendingRequests being");
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest];
        
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest];
        
        if (didRespondCompletely)
        {
            NSLog(@"didRespondCompletely");
            [requestsCompleted addObject:loadingRequest];
            [loadingRequest finishLoading];
        }
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];
    
    NSLog(@"processPendingRequests end");
}


#pragma mark -
- (void)didRLDownloadTaskDataRefresh:(TTDownloadTask *)downloadTask
{
    [self processPendingRequests];
}


- (void)didRLDownloadTaskDataFinished:(TTDownloadTask *)downloadTask
{
}



@end
