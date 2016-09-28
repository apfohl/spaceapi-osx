//
//  SAPISpaceFed.m
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import "SAPISpaceFed.h"

@implementation SAPISpaceFed

- (NSDictionary*) jsonMapping {
    return @{@"spacenet":@"NSNumber",
             @"spacesaml":@"NSNumber",
             @"spacephone":@"NSNumber"};
}

@end
