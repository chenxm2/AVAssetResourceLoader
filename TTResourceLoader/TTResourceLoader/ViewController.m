//
//  ViewController.m
//  TTResourceLoader
//
//  Created by xianmingchen on 16/3/29.
//  Copyright © 2016年 xianmingchen. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "TTAVAssetResourceLoader.h"
#import "TTMoviePlayerView.h"

@interface ViewController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *currentItem;
    @property (weak, nonatomic) IBOutlet TTMoviePlayerView *playerView;
@property (nonatomic, strong) TTAVAssetResourceLoader *ttAVAssetResourceLoader;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)playerClicked:(id)sender {

    if (self.currentItem)
    {
        [self.currentItem removeObserver:self forKeyPath:@"status" context:NULL];
        self.currentItem = nil;
    }
    
    
    self.ttAVAssetResourceLoader = [[TTAVAssetResourceLoader alloc] init];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[self songURLWithCustomScheme:@"stream"] options:nil];
    [asset.resourceLoader setDelegate:self.ttAVAssetResourceLoader queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [(AVPlayerLayer*)[self.playerView layer] setPlayer:self.player];
    

    self.currentItem = playerItem;
}

- (NSURL *)songURL
{
    //短
    //    return [NSURL URLWithString:@"http://godmusic.bs2dl.yy.com/godmusicAdmin_1420701586213_h264.mp4"];
    //长
    return [NSURL URLWithString:@"http://godmusic.bs2dl.yy.com/godmusicAdmin_1419559724587_h264.mp4"];
}
    
- (NSURL *)songURLWithCustomScheme:(NSString *)scheme
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[self songURL] resolvingAgainstBaseURL:NO];
    components.scheme = scheme;
    
    return [components URL];
}


#pragma KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
        //    NSLog(@"didCancelLoadingRequest:%@", change);
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay)
    {
        [self.player play];
    }
}


@end
