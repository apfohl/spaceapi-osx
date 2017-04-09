//
//  SAPILocation.m
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import "SAPILocation.h"

@implementation SAPILocation

- (NSDictionary*) jsonMapping {
    return @{@"address":@"NSString",
             @"lat":@"NSNumber",
             @"lon":@"NSNumber"};
}

@end
