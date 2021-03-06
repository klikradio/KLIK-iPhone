//
//  KRFirstViewController.m
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//
/*#if DEBUG
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
#endif*/
#import "KRNowPlayingController.h"
#import "Reachability.h"
#import "KRAppDelegate.h"

@interface KRNowPlayingController ()

@end

@implementation KRNowPlayingController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [(KRAppDelegate *)[[UIApplication sharedApplication] delegate] setController:self];
    NowPlayingVolume.backgroundColor = [UIColor clearColor];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight == 568)
    {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg2-568h.png"]];
    }
    else
    {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg2.png"]];
    }
    
}

- (void)startStreamer
{
    if ([reach currentReachabilityStatus] == ReachableViaWiFi)
    {
        streamer = [[AudioStreamer alloc] initWithURL:[NSURL URLWithString:@"http://klikradio.org/klik"]];
    }
    else if ([reach currentReachabilityStatus] == ReachableViaWWAN)
    {
        streamer = [[AudioStreamer alloc] initWithURL:[NSURL URLWithString:@"http://klikradio.org/mobileklik"]];
    }
    
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
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(streamError:)
     name:ASPresentAlertWithTitleNotification
     object:streamer];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(headphonesUnplugged:)
     name:@"KLIKHeadphonesUnplugged"
     object:streamer];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [streamer start];
}

- (void)headphonesUnplugged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (streamer != nil)
        {
            if ([streamer isPlaying])
            {
                [streamer pause];
            }
        }
    });
}

- (void)startStream
{
    if (reach == nil && streamer == nil)
    {
        reach = [Reachability reachabilityWithHostName:@"apple.com"];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(reachabilityChanged:)
         name:kReachabilityChangedNotification
         object:nil];
        
        [reach startNotifier];
    }
    else
    {
        if (streamer == nil)
        {
            [self startStreamer];
        }
    }
}

- (void) stopStream
{
    if (streamer != nil)
    {
        [streamer stop];
        streamer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASPresentAlertWithTitleNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASUpdateMetadataNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
    [NowPlayingBuffering stopAnimating];
    [NowPlayingArtist setText:@""];
    [NowPlayingTitle setText:@""];
    [NowPlayingImage setImage:[UIImage imageNamed:@"noalbum.png"]];
}

- (void) reachabilityChanged:(NSNotification *)notification
{
    Reachability *curReach = [notification object];
    
    if ([curReach currentReachabilityStatus] == NotReachable)
    {
        [self stopStream];
        
        UIAlertView *sorry = [[UIAlertView alloc] initWithTitle:@"No Internet" message:@"Sorry, but we can't seem to get connected to the Internet.  Check to make sure your Internet works and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [sorry show];
        
        [NowPlayingBuffering stopAnimating];
        [NowPlayingArtist setText:@"No Internet"];
        [NowPlayingTitle setText:@""];
        [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
        [NowPlayingImage setImage:[UIImage imageNamed:@"wifi.png"]];
        
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
    else
    {
        if (streamer != nil)
        {
            [streamer stop];
            streamer = nil;
        }
        
        [self startStreamer];
    }
}

- (void) streamChanged:(NSNotification *)notification
{
    if ([streamer isWaiting]) {
        [NowPlayingBuffering startAnimating];
        [NowPlayingBuy setEnabled:NO];
    }
    else if ([streamer isPlaying]) {
        [NowPlayingBuffering stopAnimating];
        [NowPlayingStop setTitle:@"Stop" forState:UIControlStateNormal];
        [NowPlayingBuy setEnabled:YES];
    }
    else if ([streamer isPaused])
    {
        [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
        [NowPlayingBuy setEnabled:NO];
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
    
    Class NPInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (NPInfoCenter)
    {
        MPNowPlayingInfoCenter *nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
        NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:streamArtist, MPMediaItemPropertyArtist,
                                  streamTitle, MPMediaItemPropertyTitle,
                                  @"KLIK Radio", MPMediaItemPropertyAlbumTitle, nil];
        nowPlaying.nowPlayingInfo = songInfo;
    }
}

- (void)streamError:(NSNotification *)notification
{
    if ([[[notification userInfo] objectForKey:@"errorcode"] intValue] == 7)
    {
        [self stopStream];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"KLIK is Offline" message:@"Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [error show];
        });
    }
}

- (IBAction)StopPressed:(id)sender
{
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
    if ([streamer isPlaying])
    {
        BOOL bAppLaunched = NO;
        NSString *searchURL = [NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@ %@", NowPlayingArtist.text, NowPlayingTitle.text];
        NSData *searchData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[searchURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        NSDictionary *searchDict = [searchData objectFromJSONData];
        NSArray *searchResults = [searchDict objectForKey:@"results"];
        if (searchResults != nil)
        {
            if ([searchResults count] > 0)
            {
                NSDictionary *searchResult = [searchResults objectAtIndex:0];
                if ([searchResult objectForKey:@"trackViewUrl"] != nil)
                {
                    NSString *viewURL = [NSString stringWithFormat:@"itms://%@", [[searchResult objectForKey:@"trackViewUrl"] substringFromIndex:7]];
                    
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:viewURL]];
                    bAppLaunched = YES;
                }
            }
            if (!bAppLaunched)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Find Song" message:@"We weren't able to link to the iTunes Store for some reason.  Sorry. :/" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

- (IBAction)PauseDown:(id)sender {
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
