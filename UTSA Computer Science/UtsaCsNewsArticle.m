//
//  UtsaCsNewsArticle.m
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 2/1/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import "UtsaCsNewsArticle.h"

@implementation UtsaCsNewsArticle

- (NSString *)title {
    if (!_title) {
        _title = [[NSString alloc] init];
    }
    return _title;
}

- (NSString *)date {
    if (!_date) {
        _date = [[NSString alloc] init];
    }
    return _date;
}


@end