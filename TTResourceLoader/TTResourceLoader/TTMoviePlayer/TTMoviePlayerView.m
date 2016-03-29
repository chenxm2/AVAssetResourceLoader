//
//  TTMoviePlayerView.m
//  TTResourceLoader
//
//  Created by xianmingchen on 16/3/29.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import "TTMoviePlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation TTMoviePlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}
    
- (AVPlayer*)player
{
    return [(AVPlayerLayer*)[self layer] player];
}
    
- (void)setPlayer:(AVPlayer*)player
{
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}
    
- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

@end
