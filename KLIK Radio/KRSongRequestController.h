//
//  KRSongRequestController.h
//  KLIK Radio
//
//  Created by Jake Wood on 9/17/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONkit.h"
#import "MBProgressHUD.h"

@interface KRSongRequestController : UITableViewController
{
    NSArray *songs;
    IBOutlet UITableView *SongTableView;
}
@end
