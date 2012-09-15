//
//  KRFirstViewController.m
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import "KRNowPlayingController.h"
#import "Reachability.h"

@interface KRNowPlayingController ()

@end

@implementation KRNowPlayingController

- (void)startStream {
    
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if ([reach currentReachabilityStatus] == ReachableViaWiFi) {
        streamer = [[AudioStreamer alloc] initWithURL:[NSURL URLWithString:@"http://majestic.wavestreamer.com:3238/"]];
        [streamer start];
        
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
    }
    else {
        UIAlertView *sorry = [[UIAlertView alloc] initWithTitle:@"No Wi-fi" message:@"Sorry, but KLIK currently doesn't have a mobile stream." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [sorry show];
        
        [NowPlayingBuffering stopAnimating];
        [NowPlayingArtist setText:@"Wi-Fi Required"];
        [NowPlayingTitle setText:@""];
        [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
        [NowPlayingImage setImage:[UIImage imageNamed:@"wifi.png"]];
    }
}

- (void) stopStream {
    [streamer stop];
    streamer = nil;
    
    [NowPlayingStop setTitle:@"Play" forState:UIControlStateNormal];
    [NowPlayingBuffering stopAnimating];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NowPlayingVolume.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    
    [self startStream];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void) newSong:(NSNotification *)notification
{
    NSString *streamArtist;
    NSString *streamTitle;
    
    NSArray *metaParts = [[[notification userInfo] objectForKey:@"metadata"] componentsSeparatedByString:@";"];
    NSString *item;
    NSMutableDictionary *hash = [[NSMutableDictionary alloc] init];
    for (item in metaParts) {
        NSArray *pair = [item componentsSeparatedByString:@"="];
        if ([pair count] == 2) {
            [hash setObject:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
        }
    }
    
    NSString *streamString = [hash objectForKey:@"StreamTitle"]; // stringByReplacingOccurrencesOfString:@"" withString:@""];
    NSArray *streamParts = [streamString componentsSeparatedByString:@" - "];
    if ([streamParts count] == 1) {
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
    
    NSDictionary *trackData = [[albumJSON objectFromJSONData] objectForKey:@"track"];
    if (trackData != nil) {
        NSDictionary *albumData = [trackData objectForKey:@"album"];
        if (albumData != nil) {
            NSArray *images = [albumData objectForKey:@"image"];
            if (images != nil) {
                [NowPlayingImage setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[images objectAtIndex:[images count] - 1] objectForKey:@"#text"]]]]];
            }
        }
    }

    [NowPlayingArtist setText:streamArtist];
    [NowPlayingTitle setText:streamTitle];
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
}

- (void)viewDidUnload
{
    NowPlayingArtist = nil;
    NowPlayingTitle = nil;
    NowPlayingImage = nil;
    NowPlayingBuffering = nil;
    NowPlayingVolume = nil;
    NowPlayingStop = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (IBAction)StopPressed:(id)sender {
    if ([streamer isPlaying]) {
        [self stopStream];
    }
    else {
        [self startStream];
    }
}

- (IBAction)BuySongPressed:(id)sender {
    NSURL *iTunes = [NSURL URLWithString:[[NSString stringWithFormat:@"itms://WebObjects/MZSearch.woa/wa/advancedSearchResults?songTerm=%@&artistTerm=%@", NowPlayingTitle.text, NowPlayingArtist.text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:iTunes];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
