//
//  KRSecondViewController.m
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import "KRDonationsViewController.h"

@interface KRDonationsViewController ()

@end

@implementation KRDonationsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSURL *url = [NSURL URLWithString:@"https://www.wepay.com/donations/klikradio"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [DonationWebView loadRequest:urlRequest];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
