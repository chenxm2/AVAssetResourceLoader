//
//  TTDownloadContentInfo.m
//  TTResourceLoader
//
//  Created by xianmingchen on 16/4/1.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import "TTDownloadContentInfo.h"
#import <MobileCoreServices/MobileCoreServices.h>
@implementation TTDownloadContentInfo
- (instancetype)initWithResponse:(NSHTTPURLResponse *)response
    {
        self = [super init];
        if (self) {
            NSString *mimeType = [response MIMEType];
            CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
            
            _contentType = CFBridgingRelease(contentType);
            _contentLength = response.expectedContentLength;
            
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
