//
//  TTDownloadContentInfo.h
//  TTResourceLoader
//
//  Created by xianmingchen on 16/4/1.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTDownloadContentInfo : NSObject
@property (nonatomic, readonly) unsigned long long contentLength;
@property (nonatomic, readonly) NSString *contentType;
@property (nonatomic, readonly) BOOL byteRangeAccessSupported;
@property (nonatomic, readonly) NSUInteger segmentBytesSize;

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response;
@end
