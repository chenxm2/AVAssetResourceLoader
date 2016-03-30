//
//  TTCache.h
//  TTResourceLoader
//
//  Created by xianmingchen on 16/3/30.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYCache.h"

@interface TTCache : NSObject
+ (YYCache *)cacheInstanceWithPath:(NSString *)fullPath;
@end
