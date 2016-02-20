//
//  UtsaCsFeedViewController.m
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 1/26/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import "AFNetworking.h"
#import "Reachability.h"
#import "TFHpple.h"
#import "UtsaCsFeedViewController.h"
#import "UtsaCsNewsArticle.h"
#import "UtsaCsNewsArticleViewController.h"

@interface UtsaCsFeedViewController ()

@end

@implementation UtsaCsFeedViewController

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
    
    // Register for font size changes that may occur by the user in iOS 7
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredFontSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    // Register for reachability changes that may occur during app usage
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:)
                                                 name:kReachabilityChangedNotification object:nil];
    
    // Load all the news feed articles using AFNetworking
    [self loadNewsFeed];
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadNewsFeed];
    [self.tableView reloadData];
}

- (void)preferredFontSizeChanged:(NSNotification *)aNotification {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSMutableArray *)articles {
    if (!_articles) {
        _articles = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _articles;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.articles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"News Article Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    UtsaCsNewsArticle *article = [self.articles objectAtIndex:indexPath.row];
    cell.textLabel.text = article.title;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.detailTextLabel.text = article.date;
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    return cell;
}

- (void)loadNewsFeed {
    
    // (1) Create a AFHTTPRequest operation using the UTSA CS News Feed URL
    NSURL *newsFeedUrl = [NSURL URLWithString:@"http://cs.utsa.edu/activities/news"];
    NSURLRequest *newsRequest = [NSURLRequest requestWithURL:newsFeedUrl];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:newsRequest];
    
    // (2) If the user has a network connection or we receive a success message, parse the HTML and
    //     refresh the table once we have all the data in place.
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        TFHpple *htmlData = [TFHpple hppleWithHTMLData:responseObject];
        
        NSString *newsFeedXpathQueryString = @"//div[@id='content']/ul/li";
        NSArray *newsFeedArticles = [htmlData searchWithXPathQuery:newsFeedXpathQueryString];
        
        for (TFHppleElement *item in newsFeedArticles) {
            NSArray *childrenItems = item.children;
            
            UtsaCsNewsArticle *article = [[UtsaCsNewsArticle alloc] init];
            [self.articles addObject:article];
            
            article.date = [[childrenItems firstObject] content];
            article.title = [[[childrenItems lastObject] firstChild] content];
            article.articleUrl = [[childrenItems lastObject] objectForKey:@"href"];
        }

        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // (3) If the user does not have a network connection or we failed whijle attempting to retrieve
        //     the HTML data, bring up a UIAlertView to notify the user.
        NSLog(@"%@", operation.responseString);
        NSLog(@"%@", error.description);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                            message:@"Could not access the UTSA website. Check your network connection."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    
    [operation start];
}

- (IBAction)refreshContent {
    
    // Start the refresh control spinner
    [self.refreshControl beginRefreshing];
    
    // Call the loadNewsFeed method to begin retrieving the data and parsing the HTML.
    dispatch_queue_t otherQueue = dispatch_queue_create("Load News Feed", NULL);
    dispatch_async(otherQueue, ^{
        [self loadNewsFeed];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    });
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable]) {
        [self loadNewsFeed];
    }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"Article View"]) {
        NSIndexPath *selectedItem = [self.tableView indexPathForSelectedRow];
        UtsaCsNewsArticle *object = [self.articles objectAtIndex:selectedItem.row];
        UtsaCsNewsArticleViewController *vc = [segue destinationViewController];
        vc.newsArticle = object.articleUrl;
    }
}

@end
