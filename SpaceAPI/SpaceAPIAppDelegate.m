//
//  SpaceAPIAppDelegate.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 14.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SpaceAPIAppDelegate.h"

@implementation SpaceAPIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.controller updateSpaceDirectory];
}

@end
