//
//  KRFirstViewController.m
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import "KRFirstViewController.h"

@interface KRFirstViewController ()

@end

@implementation KRFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    streamer = [[AudioStreamer alloc] initWithURL:[NSURL URLWithString:@"http://majestic.wavestreamer.com:3238/"]];

    [streamer start];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(newSong:)
     name:ASUpdateMetadataNotification
     object:streamer];
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
    
    NSString *streamString = [[hash objectForKey:@"StreamTitle"] stringByReplacingOccurrencesOfString:@"'" withString:@""];
    NSArray *streamParts = [streamString componentsSeparatedByString:@" - "];
    if ([streamParts count] == 1) {
        streamArtist = @"";
        streamTitle = [streamParts objectAtIndex:0];
    }
    else if ([streamParts count] == 2) {
        streamArtist = [streamParts objectAtIndex:0];
        streamTitle = [streamParts objectAtIndex:1];
    }
    
    [TempNP setText:[NSString stringWithFormat:@"%@ by %@", streamTitle, streamArtist]];
    //[TempNowPlaying setText:[NSString stringWithFormat:@"%@ by %@", streamTitle, streamArtist]];
}

- (void)viewDidUnload
{
    TempNP = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
