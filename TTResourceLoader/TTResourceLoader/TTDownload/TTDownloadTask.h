//
//  RLDownloadTask.h
//
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TTDownloadTask;

@interface RLContentInformation : NSObject
@property (nonatomic, assign)unsigned long long contentLength;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, strong) NSMutableArray *validDataRangeArray;   //had sorted
@end

@protocol TTDownloadTaskDelegate <NSObject>
@optional
- (void)didRLDownloadTaskDataRefresh:(TTDownloadTask *)downloadTask;
- (void)didRLDownloadTaskDataFinished:(TTDownloadTask *)downloadTask;
@end

@interface TTDownloadTask : NSObject
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, readonly, strong) RLContentInformation *contentInformation;
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, weak) id<TTDownloadTaskDelegate> delegate;
@property (nonatomic, readonly) NSArray *allRLDownloadSegment;

- (id)initWithURL:(NSURL *)url;
- (void)startTask:(void (^)(BOOL success))successBlock;

- (NSData *)dataWithOffset:(unsigned long long)offset length:(unsigned long long)length actuallyReadLength:(unsigned long long *)actuLength;
@end
