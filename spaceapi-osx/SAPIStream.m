//
//  SAPIStream.m
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import "SAPIStream.h"

@implementation SAPIStream

- (NSDictionary*) jsonMapping {
    return @{@"m4":@"NSString",
             @"mjpeg":@"NSString",
             @"ustream":@"NSString"};
}

@end
