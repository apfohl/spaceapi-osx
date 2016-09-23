//
//  SAPIAppDelegate.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SAPIAppDelegate.h"

@implementation SAPIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.controller fetchSpaceDirectory];
}

@end
