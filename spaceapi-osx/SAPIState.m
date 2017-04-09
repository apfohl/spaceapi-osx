//
//  SAPIState.m
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import "SAPIState.h"

@implementation SAPIState

- (NSDictionary*) jsonMapping {
    return @{@"open":@"NSString",
             @"lastchange":@"NSString",
             @"trigger_person":@"NSString",
             @"message":@"NSString",
             @"icon":@"SAPIIcon",
             };
}

@end
