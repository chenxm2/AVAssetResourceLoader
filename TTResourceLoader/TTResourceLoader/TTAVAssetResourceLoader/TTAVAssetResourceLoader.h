//
//  TTAVAssetResourceLoader.h
//  TTResourceLoader
//
//  Created by xianmingchen on 16/3/29.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface TTAVAssetResourceLoader : NSObject <AVAssetResourceLoaderDelegate>

- (void)stopTimer;
@end
