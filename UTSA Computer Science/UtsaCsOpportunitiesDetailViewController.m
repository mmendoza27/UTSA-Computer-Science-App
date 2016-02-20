//
//  UtsaCsOpportunitiesDetailViewController.m
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 5/19/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import "UtsaCsOpportunitiesDetailViewController.h"

@interface UtsaCsOpportunitiesDetailViewController ()

@property (strong, nonatomic) IBOutlet UILabel *opportunityDetailsLabel;

@end

@implementation UtsaCsOpportunitiesDetailViewController

- (NSString *)details {
    if (!_details) {
        _details = [[NSString alloc] init];
    }
    return _details;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.opportunityDetailsLabel.text = self.details;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
