//
//  KRRequestConnectionDelegate.m
//  KLIK Radio
//
//  Created by Jake Wood on 9/18/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import "KRRequestConnectionDelegate.h"

@implementation KRRequestConnectionDelegate

-(id) initWithView:(KRSongRequestController *)_controller
{
    self = [super init];
    if (self) {
        self.controller = _controller;
    }
    return self;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [MBProgressHUD hideHUDForView:self.controller.view animated:YES];
    
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.controller.view];
    [self.controller.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    HUD.labelText = @"Request Sent!";
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.delegate = nil;
    
    [HUD show:YES];
    [HUD hide:YES afterDelay:1];
    
    NSLog(@"%@", [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding]);
}
@end
