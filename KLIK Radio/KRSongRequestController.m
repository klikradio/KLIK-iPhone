//
//  KRSongRequestController.m
//  KLIK Radio
//
//  Created by Jake Wood on 9/17/12.
//  Copyright (c) 2012 KLIK Radio. All rights reserved.
//

#import "KRSongRequestController.h"
#import "KRRequestConnectionDelegate.h"

@interface KRSongRequestController ()
@end

@implementation KRSongRequestController
@synthesize SongSearchBar;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSData *songData = [[NSData alloc] initWithContentsOfURL:[[NSURL alloc] initWithString:@"http://samapi.klikradio.org/songs/?limit=5&sort=date_added&desc=1"]];
    songs = [songData objectFromJSONData];
}

- (void)viewDidUnload
{
    SongTableView = nil;
    [self setSongSearchBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // Hide the table...
    [searchBar setShowsCancelButton:YES animated:YES];
    self.tableView.allowsSelection = NO;
    self.tableView.scrollEnabled = NO;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.SongSearchBar resignFirstResponder];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *urlString = [NSString
                           stringWithFormat:@"http://samapi.klikradio.org/songs/?term=%@&sort=date_added&desc=1",
                           [self.SongSearchBar text]];
    NSURL *url = [[NSURL alloc]
                  initWithString:[urlString
                                  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:15];
    
    receivedData = [[NSMutableData alloc] init];
    NSURLConnection *urlConnection = [[NSURLConnection alloc]
                                      initWithRequest:urlRequest
                                      delegate:self];
    if (!urlConnection)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Error Connecting"
                              message:@"Sorry, but we couldn't connect to KLIK's request server.  Please try again later."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
}

- (void)connection:(NSURLConnection *)urlConnection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    songs = [receivedData objectFromJSONData];
    [self.tableView reloadData];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.tableView)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableView)
    {
        return [songs count];
    }
    else
    {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        NSLog(@"CELL IS NIL!!! THATS THE PROBLEM!");
    }
    else
    {
        // Configure the cell...
        cell.textLabel.text = [[songs objectAtIndex:indexPath.row] objectForKey:@"title"];
        cell.detailTextLabel.text = [[songs objectAtIndex:indexPath.row] objectForKey:@"artist"];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    songRequestID = [[songs objectAtIndex:indexPath.row] objectForKey:@"ID"];
    NSString *message = [[NSString alloc] initWithFormat:@"Are you sure you want to request %@ by %@?",
                         [[songs objectAtIndex:indexPath.row] objectForKey:@"title"],
                         [[songs objectAtIndex:indexPath.row] objectForKey:@"artist"]];
    UIAlertView *requestVerify = [[UIAlertView alloc] initWithTitle:@"Request" message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [requestVerify show];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonName = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonName isEqualToString:@"Yes"])
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.tableView.allowsSelection = NO;
        self.tableView.scrollEnabled = NO;
        
        KRRequestConnectionDelegate *requestDelegate = [[KRRequestConnectionDelegate alloc] initWithView:self];
        
        NSMutableURLRequest *requestRequest = [[NSMutableURLRequest alloc]
                                                initWithURL:[[NSURL alloc]
                                                             initWithString:[NSString
                                                                             stringWithFormat:
                                                                             @"http://samapi.klikradio.org/request/%@",
                                                                             songRequestID]]];
        [requestRequest setHTTPMethod:@"POST"];
        
        NSURLConnection *requestConnection = [[NSURLConnection alloc] initWithRequest:requestRequest delegate:requestDelegate];
        
        self.tableView.allowsSelection = YES;
        self.tableView.scrollEnabled = YES;
        
        NSLog(@"Request ID %@", songRequestID);
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

@end
