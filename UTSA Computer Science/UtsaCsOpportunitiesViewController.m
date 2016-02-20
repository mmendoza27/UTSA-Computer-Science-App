//
//  UtsaCsOpportunitiesViewController.m
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 4/18/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import "AFNetworking.h"
#import "UtsaCsOpportunitiesViewController.h"
#import "UtsaCsOpportunitiesDetailViewController.h"
#import "UtsaCsNotificationsViewController.h"

@interface UtsaCsOpportunitiesViewController ()

@property (strong, nonatomic) NSMutableArray *notificationTypes;
@property (strong, nonatomic) NSMutableArray *preferredNotifications;
@property (strong, nonatomic) NSMutableArray *preferredOpportunities;
@property (strong, nonatomic) NSMutableArray *otherOpportunities;

@end

@implementation UtsaCsOpportunitiesViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredFontSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification object:nil];

    [self retrieveOpportunities];
}

- (void)viewWillAppear:(BOOL)animated {
    [self retrieveOpportunities];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)preferredFontSizeChanged:(NSNotification *)aNotification {
    [self.tableView reloadData];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSInteger numberOfRows;
    
    switch (section)
    {
        case 0:
            numberOfRows = self.preferredOpportunities.count;
            break;
        case 1:
            numberOfRows = self.otherOpportunities.count;
            break;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Opportunities Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self.preferredOpportunities objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionName;
    
    switch (section)
    {
        case 0:
            sectionName = @"Preferred Opportunities";
            break;
        case 1:
            sectionName = @"Other Opportunities";
            break;
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (void)retrieveOpportunities {
    // Application will try to utilize the list of preferred notifications and all notification types
    self.preferredNotifications = [[NSUserDefaults standardUserDefaults] objectForKey:@"UtsaCsUserPreferredPreferences"];
    NSString *preferredPreferencesString = [self.preferredNotifications componentsJoinedByString:@"|"];
    
    NSString *finalUrlString = [preferredPreferencesString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *preferredNotificationsUrlString = @"http://162.209.104.58/pushNotifications/retrievePreferredNotifications.php?types=";
    preferredNotificationsUrlString = [preferredNotificationsUrlString stringByAppendingString:finalUrlString];
    
    NSURL *preferredPreferencesUrl = [NSURL URLWithString:preferredNotificationsUrlString];
    NSURLRequest *preferredPreferencesRequest = [NSURLRequest requestWithURL:preferredPreferencesUrl];
    AFHTTPRequestOperation *preferredPreferencesOperation = [[AFHTTPRequestOperation alloc] initWithRequest:preferredPreferencesRequest];
    
    [preferredPreferencesOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Parse out the JSON data
        NSError* error;
        NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        NSMutableArray* prefOpportunities = [[NSMutableArray alloc] init];
        
        for (NSDictionary* databaseTypes in jsonResponse) {
            [prefOpportunities addObject:[databaseTypes valueForKey:@"title"]];
        }
        
        self.preferredOpportunities = [prefOpportunities copy];
        NSLog(@"Results: %@", self.preferredOpportunities);
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", operation.responseString);
        NSLog(@"%@", error.description);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                            message:@"Could not retrieve any opportunities. Please check your network connection."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    
    NSString *otherNotificationsUrlString = @"http://162.209.104.58/pushNotifications/retrieveOtherNotifications.php?otherTypes=";
    otherNotificationsUrlString = [otherNotificationsUrlString stringByAppendingString:finalUrlString];
    
    NSURL *otherPreferencesUrl = [NSURL URLWithString:otherNotificationsUrlString];
    NSURLRequest *otherPreferencesRequest = [NSURLRequest requestWithURL:otherPreferencesUrl];
    AFHTTPRequestOperation *otherPreferencesOperation = [[AFHTTPRequestOperation alloc] initWithRequest:otherPreferencesRequest];
    
    [otherPreferencesOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Parse out the JSON data
        NSError* error;
        NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
        NSMutableArray* otherOpportunities = [[NSMutableArray alloc] init];
        
        for (NSDictionary* databaseTypes in jsonResponse) {
            [otherOpportunities addObject:[databaseTypes valueForKey:@"title"]];
        }
        
        self.otherOpportunities = [otherOpportunities copy];
        NSLog(@"Results: %@", self.otherOpportunities);
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", operation.responseString);
        NSLog(@"%@", error.description);
    }];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:3];
    [operationQueue addOperations:@[preferredPreferencesOperation, otherPreferencesOperation] waitUntilFinished:NO];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"Opportunity Details"]) {
        // NSIndexPath *selectedItem = [self.tableView indexPathForSelectedRow];
        NSString *details = @"Some details...";
        UtsaCsOpportunitiesDetailViewController *vc = [segue destinationViewController];
        vc.details = details;
    }
}

@end
