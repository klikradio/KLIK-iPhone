//
//  KRFirstViewController.h
//  KLIK Radio
//
//  Created by Jake Wood on 9/14/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioStreamer.h"

@interface KRFirstViewController : UIViewController
{
    AudioStreamer *streamer;
    IBOutlet UILabel *TempNP;
}

@end
