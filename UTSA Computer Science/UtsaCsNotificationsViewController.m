//
//  UtsaCsNotificationsViewController.m
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 1/26/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import "AFNetworking.h"
#import "UtsaCsNotificationsViewController.h"
#import "Reachability.h"

@interface UtsaCsNotificationsViewController ()

@property (strong, nonatomic) NSMutableArray *notificationTypes;
@property (strong, nonatomic) NSMutableArray *listOfApprovedNotifications;

@end

@implementation UtsaCsNotificationsViewController

#pragma mark - Lazy Instantiators
- (NSMutableArray *)notificationTypes {
    if (!_notificationTypes) {
        _notificationTypes = [[NSMutableArray alloc] init];
    }
    return _notificationTypes;
}

- (NSMutableArray *)listOfApprovedNotifications {
    if (!_listOfApprovedNotifications) {
        _listOfApprovedNotifications = [[NSMutableArray alloc] init];
    }
    return _listOfApprovedNotifications;
}

- (NSMutableDictionary *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableDictionary alloc] initWithObjects:self.listOfApprovedNotifications
                                                           forKeys:self.notificationTypes];
    }
    
    return _dataSource;
}

#pragma mark - Application Lifecycle Methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredFontSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    // Register for reachability changes that may occur during app usage
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:)
                                                 name:kReachabilityChangedNotification object:nil];

    
    [self loadDatabaseTypes];
    [self loadNotificationPreferencesFromDatabase];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadNotificationPreferencesFromDatabase];
    [self.tableView reloadData];
}

- (void)preferredFontSizeChanged:(NSNotification *)aNotification {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notificationTypes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Push Notification Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self.notificationTypes objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UISwitch *notificationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [notificationSwitch addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = notificationSwitch;
    
    if ([self.listOfApprovedNotifications containsObject:cell.textLabel.text]) {
        notificationSwitch.on = true;
    }
    
    return cell;
}

- (IBAction)switchDidChange:(UISwitch *)source {
    NSMutableArray *notificationsArray = [[NSMutableArray alloc] init];
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    UISwitch *notificationSwitch = [[UISwitch alloc] init];
    
    for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j) {
        for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i) {
            cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]];
            notificationSwitch = (UISwitch *)cell.accessoryView;
            
            if (notificationSwitch.on) {
                [notificationsArray addObject:cell.textLabel.text];
            }
            
            // [[NSUserDefaults standardUserDefaults] setBool:notificationSwitch.on forKey:cell.textLabel.text];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:notificationsArray forKey:@"UtsaCsUserPreferredPreferences"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *newNotificationsPrefsString = [notificationsArray componentsJoinedByString:@",%20"];
    NSString *uuidString = [[NSUserDefaults standardUserDefaults] stringForKey:@"UtsaCsUUID"];
    
    [self updateNotificationPreferences:newNotificationsPrefsString withUUID:uuidString];
}

- (void)updateNotificationPreferences:(NSString *)updatedPreferences withUUID:(NSString *)uuid {
    NSString *updatedPreferencesUrlString = @"http://162.209.104.58/pushNotifications/updatePrefs.php?notificationtypes=";
    updatedPreferencesUrlString = [updatedPreferencesUrlString stringByAppendingString:updatedPreferences];
    updatedPreferencesUrlString = [updatedPreferencesUrlString stringByAppendingString:@"&uid="];
    updatedPreferencesUrlString = [updatedPreferencesUrlString stringByAppendingString:uuid];
    
    NSString *finalUrlString = [updatedPreferencesUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *updatePreferencesUrl = [NSURL URLWithString:finalUrlString];
    NSURLRequest *updatePreferencesRequest = [NSURLRequest requestWithURL:updatePreferencesUrl];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:updatePreferencesRequest];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Database successfully updated with %@", updatedPreferences);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", operation.responseString);
        NSLog(@"%@", error.description);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                            message:@"Could not update your notification preferences. Please check your network connection."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    
    [operation start];
}

- (void)loadDatabaseTypes {
    NSURL *retrieveTypesUrl = [NSURL URLWithString:@"http://162.209.104.58/pushNotifications/retrieveTypes.php"];
    NSURLRequest *retrieveTypesRequest = [NSURLRequest requestWithURL:retrieveTypesUrl];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:retrieveTypesRequest];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Parse out the JSON data
        NSError* error;
        NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        NSMutableArray* types = [[NSMutableArray alloc] init];
        
        for (NSDictionary* databaseTypes in jsonResponse) {
            [types addObject:[databaseTypes valueForKey:@"notification_type"]];
        }

        [[NSUserDefaults standardUserDefaults] setObject:types forKey:@"UtsaCsDatabaseTypes"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.notificationTypes = [types copy];
        NSLog(@"Results: %@", self.notificationTypes);
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.notificationTypes = [[NSUserDefaults standardUserDefaults] objectForKey:@"UtsaCsDatabaseTypes"];
        [self.tableView reloadData];
        NSLog(@"%@", operation.responseString);
        NSLog(@"%@", error.description);
    }];
    
    [operation start];
}

- (void)loadNotificationPreferencesFromDatabase {
    // Application will use the iPhone UUID to send a URL request to grab the user's specific preferences
    NSString *deviceUuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"UtsaCsUUID"];
    NSString *notificationsUrlString = @"http://162.209.104.58/pushNotifications/retrievePrefs.php?uid=";
    notificationsUrlString = [notificationsUrlString stringByAppendingString:deviceUuid];
    
    NSURL *retrieveNotificationPreferencesUrl = [NSURL URLWithString:notificationsUrlString];
    NSURLRequest *retrieveNotificationPreferencesRequest = [NSURLRequest requestWithURL:retrieveNotificationPreferencesUrl];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:retrieveNotificationPreferencesRequest];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Parse out the JSON data
        NSError* error;
        NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        NSMutableArray* prefs = [[NSMutableArray alloc] init];
        
        for (NSDictionary* databaseTypes in jsonResponse) {
            [prefs addObject:[databaseTypes valueForKey:@"preference"]];
        }

        [[NSUserDefaults standardUserDefaults] setObject:prefs forKey:@"UtsaCsUserPreferredPreferences"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.listOfApprovedNotifications = [prefs copy];
        
        NSLog(@"Results: %@", self.listOfApprovedNotifications);
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.notificationTypes = [[NSUserDefaults standardUserDefaults] objectForKey:@"UtsaCsUserPreferredPreferences"];
        [self.tableView reloadData];
        NSLog(@"%@", operation.responseString);
        NSLog(@"%@", error.description);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                            message:@"Could not retrieve your notification preferences from the database. Please check your network connection."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    
    [operation start];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable]) {
        [self loadDatabaseTypes];
        [self loadNotificationPreferencesFromDatabase];
    }
}

@end
