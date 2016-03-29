//
//  TTMoviePlayerView.h
//  TTResourceLoader
//
//  Created by xianmingchen on 16/3/29.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;
@interface TTMoviePlayerView : UIView
@property (nonatomic, strong) AVPlayer *player;
    
- (void)setPlayer:(AVPlayer *)player;
    
    /*! Specifies how the video is displayed within a player layer’s bounds.
     (AVLayerVideoGravityResizeAspect is default)
     @param NSString fillMode
     */
- (void)setVideoFillMode:(NSString *)fillMode;

@end
