//
//  RLDownloadTask.h
//
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TTDownloadTask;
@class TTDownloadContentInfo;

@protocol TTDownloadTaskDelegate <NSObject>
@optional
- (void)didRLDownloadTaskDataRefresh:(TTDownloadTask *)downloadTask;
- (void)didRLDownloadTaskDataFinished:(TTDownloadTask *)downloadTask;
@end

@interface TTDownloadTask : NSObject
@property (nonatomic, readonly, strong) TTDownloadContentInfo *downloadContentInfo;
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, weak) id<TTDownloadTaskDelegate> delegate;
@property (nonatomic, readonly) NSArray *allRLDownloadSegment;
@property (nonatomic, readonly) NSUInteger segmentBytesSize;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

- (id)initWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url downloadSegmentBytesSize:(NSUInteger)size NS_DESIGNATED_INITIALIZER;
- (void)startTask:(void (^)(BOOL success))successBlock;

- (void)dataWithOffset:(unsigned long long)offset length:(unsigned long long)length completedBlock:(void (^) (NSData *data, unsigned long long offset,  unsigned long long actullyLength))completeBlock;

//- (NSData *)dataWithOffset:(unsigned long long)offset length:(unsigned long long)length actuallyReadLength:(unsigned long long *)actuLength;

@end
