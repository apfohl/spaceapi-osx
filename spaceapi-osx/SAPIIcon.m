//
//  SAPIIcon.m
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import "SAPIIcon.h"

@implementation SAPIIcon

- (NSDictionary*) jsonMapping {
    return @{@"open":@"NSString",
             @"closed":@"NSString"
             };
}

@end
