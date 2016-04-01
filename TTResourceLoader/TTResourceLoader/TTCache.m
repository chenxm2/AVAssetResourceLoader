//
//  TTCache.m
//  TTResourceLoader
//
//  Created by xianmingchen on 16/3/30.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import "TTCache.h"

@implementation TTCache

+ (YYCache *)cacheInstanceWithPath:(NSString *)fullPath
{
    static CFMutableDictionaryRef yyCacheCache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        yyCacheCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

        lock = dispatch_semaphore_create(1);
    });
    
    
    YYCache *cache = nil;
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    BOOL createPathSucceed = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fullPath])
    {
        createPathSucceed = YES;
    }
    else
    {
        BOOL created =  [fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:NULL];
        
        if (created)
        {
            createPathSucceed = YES;
        }
        else
        {
            createPathSucceed = NO;
        }
    }
    
    if (createPathSucceed)
    {
        cache = CFDictionaryGetValue(yyCacheCache, (__bridge const void *)fullPath);
        dispatch_semaphore_signal(lock);
        if (!cache)
        {
            cache = [[YYCache alloc] initWithPath:fullPath];
            if (cache) {
                dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
                CFDictionarySetValue(yyCacheCache, (__bridge const void *)(fullPath), (__bridge const void *)cache);
                dispatch_semaphore_signal(lock);
            }
        }
    }
    
    return cache;
}
@end
