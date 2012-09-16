//
//  KRFirstViewController.m
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import "KRNowPlayingController.h"
#import "Reachability.h"
#import "KRAppDelegate.h"

@interface KRNowPlayingController ()

@end

@implementation KRNowPlayingController

- (void)viewDidLoad
{
    [(KRAppDelegate *)[[UIApplication sharedApplication] delegate] setController:self];
    
    [super viewDidLoad];
    
    NowPlayingVolume.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg2.png"]];
    
    [self startStream];
}


- (void)startStream
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if ([reach currentReachabilityStatus] == ReachableViaWiFi)
    {
        if (streamer == nil)
        {
            streamer = [[AudioStreamer alloc] initWithURL:[NSURL URLWithString:@"http://majestic.wavestreamer.com:3238/"]];
            
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(newSong:)
             name:ASUpdateMetadataNotification
             object:streamer];
            
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(streamChanged:)
             name:ASStatusChangedNotification
             object:streamer];
            
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            [streamer start];
        }
    }
    else
    {
        UIAlertView *sorry = [[UIAlertView alloc] initWithTitle:@"No Wi-fi" message:@"Sorry, but KLIK currently doesn't have a mobile stream." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [sorry show];
        
        [NowPlayingBuffering stopAnimating];
        [NowPlayingArtist setText:@"Wi-Fi Required"];
        [NowPlayingTitle setText:@""];
        [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
        [NowPlayingImage setImage:[UIImage imageNamed:@"wifi.png"]];
        
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}

- (void) stopStream
{
    [streamer stop];
    streamer = nil;
    
    [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
    [NowPlayingBuffering stopAnimating];
    [NowPlayingArtist setText:@""];
    [NowPlayingTitle setText:@""];
    [NowPlayingImage setImage:[UIImage imageNamed:@"noalbum.png"]];
}

- (void) streamChanged:(NSNotification *)notification
{
    if ([streamer isWaiting]) {
        [NowPlayingBuffering startAnimating];
    }
    else if ([streamer isPlaying]) {
        [NowPlayingBuffering stopAnimating];
        [NowPlayingStop setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else if ([streamer isPaused])
    {
        [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
    }
}


- (void) newSong:(NSNotification *)notification
{
    NSString *streamArtist;
    NSString *streamTitle;
    
    NSArray *metaParts = [[[notification userInfo] objectForKey:@"metadata"] componentsSeparatedByString:@";"];
    NSString *item;
    NSMutableDictionary *hash = [[NSMutableDictionary alloc] init];
    for (item in metaParts)
    {
        NSArray *pair = [item componentsSeparatedByString:@"="];
        if ([pair count] == 2)
        {
            [hash setObject:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
        }
    }
    
    NSString *streamString = [hash objectForKey:@"StreamTitle"];
    NSArray *streamParts = [streamString componentsSeparatedByString:@" - "];
    if ([streamParts count] == 1)
    {
        streamArtist = @"";
        streamTitle = [[streamParts objectAtIndex:0] substringFromIndex:1];
    }
    else if ([streamParts count] == 2) {
        streamArtist = [[streamParts objectAtIndex:0] substringFromIndex:1];
        streamTitle = [streamParts objectAtIndex:1];
        streamTitle = [streamTitle substringToIndex:([streamTitle length] - 1)];
    }
    
    // Build the URL...
    NSString *albumURL = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=02ebc4801d6302410cd413154050b02a&artist=%@&track=%@&format=json", streamArtist, streamTitle];
    NSURL *albumRealURL = [NSURL URLWithString:[albumURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSData *albumJSON = [NSData dataWithContentsOfURL:albumRealURL];
    
    BOOL bAlbumArtAdded = NO;
    NSDictionary *trackData = [[albumJSON objectFromJSONData] objectForKey:@"track"];
    if (trackData != nil)
    {
        NSDictionary *albumData = [trackData objectForKey:@"album"];
        if (albumData != nil)
        {
            NSArray *images = [albumData objectForKey:@"image"];
            if (images != nil)
            {
                [NowPlayingImage setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[images objectAtIndex:[images count] - 1] objectForKey:@"#text"]]]]];
                bAlbumArtAdded = YES;
            }
        }
    }
    if (!bAlbumArtAdded)
    {
        [NowPlayingImage setImage:[UIImage imageNamed:@"noalbum.png"]];
    }

    [NowPlayingArtist setText:streamArtist];
    [NowPlayingTitle setText:streamTitle];
}


- (IBAction)StopPressed:(id)sender
{
    
     #if DEBUG
     switch ([streamer state])
     {
     case AS_INITIALIZED:
     NSLog(@"AsInitialized");
     break;
     case AS_STARTING_FILE_THREAD:
     NSLog(@"As starting file thread");
     break;
     case AS_WAITING_FOR_DATA:
     NSLog(@"As waiting for data");
     break;
     case AS_BUFFERING:
     NSLog(@"Buffering");
     break;
     case AS_FLUSHING_EOF:
     NSLog(@"Flushing EOF");
     break;
     case AS_PAUSED:
     NSLog(@"Paused");
     break;
     case AS_PLAYING:
     NSLog(@"Playing");
     break;
     case AS_STOPPED:
     NSLog(@"Stopped");
     break;
     case AS_STOPPING:
     NSLog(@"STopping");
     break;
     case AS_WAITING_FOR_QUEUE_TO_START:
     NSLog(@"Waiting for queue to start");
     break;
     
     }
     #endif
    if (streamer == nil)
    {
        [self startStream];
    }
    else
    {
        if ([streamer isPlaying] || streamer.state == AS_INITIALIZED)
        {
            [self stopStream];
        }
        else
        {
            if ([streamer isPaused])
            {
                [streamer start];
            }
            else
            {
                [self startStream];
            }
        }
    }
}

- (IBAction)BuySongPressed:(id)sender
{
    NSURL *iTunes = [NSURL URLWithString:[[NSString stringWithFormat:@"itms://WebObjects/MZSearch.woa/wa/advancedSearchResults?songTerm=%@&artistTerm=%@", NowPlayingTitle.text, NowPlayingArtist.text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:iTunes];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewDidUnload
{
    NowPlayingArtist = nil;
    NowPlayingTitle = nil;
    NowPlayingImage = nil;
    NowPlayingBuffering = nil;
    NowPlayingVolume = nil;
    NowPlayingStop = nil;
    NowPlayingBuy = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

@end
