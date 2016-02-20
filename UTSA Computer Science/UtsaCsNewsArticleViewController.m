//
//  UtsaCsNewsArticleViewController.m
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 2/1/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import "UtsaCsNewsArticleViewController.h"

@interface UtsaCsNewsArticleViewController () <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *newsArticleWebView;

@end

@implementation UtsaCsNewsArticleViewController

- (NSString *)newsArticle {
    if (!_newsArticle) {
        _newsArticle = [[NSString alloc] init];
    }
    return _newsArticle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a URL using the NSString passed from the UtsaCsFeedViewController.
    NSURL *url = [NSURL URLWithString:self.newsArticle];
    NSURLRequest *requestPage = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval:10.0];
    
    self.newsArticleWebView.delegate = self;
    
    // Load the web view using the request.
    [self.newsArticleWebView loadRequest:requestPage];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                        message:@"Could not access the UTSA website. Check your network connection."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
