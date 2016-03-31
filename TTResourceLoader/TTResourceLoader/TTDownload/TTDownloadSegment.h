//
//  TTDownloadSegment.h
//  aaa
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TTDownloadSegment;
@class YYCache;

@protocol TTDownloadSegmentDelegate <NSObject>
- (void)didSegmentFinished:(TTDownloadSegment *)segment;
@end

@interface TTDownloadSegment : NSObject

@property (nonatomic, weak) id<TTDownloadSegmentDelegate> delegate;
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, assign, readonly) unsigned long long offset;
@property (nonatomic, assign, readonly) unsigned long long length;
@property (nonatomic, readonly, getter = isDownloaded) BOOL downloaded;
@property (nonatomic, readonly) YYCache *yyCache;

- (id)initWithURL:(NSURL *)url offset:(unsigned long long)offset length:(unsigned long long)length;

- (NSData *)segmentData;

@end
