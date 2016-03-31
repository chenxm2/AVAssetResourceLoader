//
//  RLDownloadTask.h
//
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TTDownloadTask;
@class TTContentInformation;


@protocol TTDownloadTaskDelegate <NSObject>
@optional
- (void)didRLDownloadTaskDataRefresh:(TTDownloadTask *)downloadTask;
- (void)didRLDownloadTaskDataFinished:(TTDownloadTask *)downloadTask;
@end

@interface TTContentInformation : NSObject
@property (nonatomic, assign)unsigned long long contentLength;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, assign) BOOL byteRangeAccessSupported;
@property (nonatomic, assign) NSUInteger segmentBytesSize;
@property (nonatomic, strong) NSMutableArray *validDataRangeArray;   //had sorted
@end

@interface TTDownloadTask : NSObject
@property (nonatomic, readonly, strong) TTContentInformation *contentInformation;
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
