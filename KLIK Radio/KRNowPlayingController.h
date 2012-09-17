//
//  KRFirstViewController.h
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AudioStreamer.h"
#import "JSONKit.h"
#include "Reachability.h"

@interface KRNowPlayingController : UIViewController
{
    AudioStreamer *streamer;
    IBOutlet UIActivityIndicatorView *NowPlayingBuffering;
    IBOutlet UIImageView *NowPlayingImage;
    IBOutlet UILabel *NowPlayingTitle;
    IBOutlet UILabel *NowPlayingArtist;
    IBOutlet UIView *NowPlayingVolume;
    IBOutlet UIButton *NowPlayingStop;
    IBOutlet UIButton *NowPlayingBuy;
    
    MPVolumeView *mpv;
}

- (IBAction)StopPressed:(id)sender;
- (IBAction)BuySongPressed:(id)sender;

@end
