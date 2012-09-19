//
//  KRRequestConnectionDelegate.h
//  KLIK Radio
//
//  Created by Jake Wood on 9/18/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"
#import "KRSongRequestController.h"

@interface KRRequestConnectionDelegate : NSObject<NSURLConnectionDelegate>
{
    NSMutableData *receivedData;
    KRSongRequestController *controller;
}
@property (nonatomic, retain) KRSongRequestController *controller;

-(id) initWithView:(KRSongRequestController *)_controller;

@end
