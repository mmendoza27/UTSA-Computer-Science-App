//
//  UtsaCsOpportunity.h
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 5/23/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UtsaCsOpportunity : NSObject

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *details;
@property (copy, nonatomic) NSString *attachmentUrl;
@property (copy, nonatomic) NSString *type;
@property (copy, nonatomic) NSString *date;

@end
