//
//  KRFirstViewController.h
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioStreamer.h"
#import "JSONKit.h"
#import <MediaPlayer/MediaPlayer.h>

@interface KRFirstViewController : UIViewController
{
    AudioStreamer *streamer;
    IBOutlet UIActivityIndicatorView *NowPlayingBuffering;
    IBOutlet UIImageView *NowPlayingImage;
    IBOutlet UILabel *NowPlayingTitle;
    IBOutlet UILabel *NowPlayingArtist;
    IBOutlet UIView *NowPlayingVolume;
    IBOutlet UIButton *NowPlayingStop;
    
    MPVolumeView *mpv;
}

- (IBAction)StopPressed:(id)sender;
- (IBAction)BuySongPressed:(id)sender;

@end
