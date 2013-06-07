//
//  SpaceAPIAppDelegate.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 07.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SpaceAPIAppDelegate.h"

@implementation SpaceAPIAppDelegate {
  int lightState;
  NSImage *redLight;
  NSImage *greenLight;
}

- (id)init {
  self = [super init];
  if(self)
  {
    lightState = 0;
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *redLightPath = [mainBundle pathForResource: @"red" ofType: @"png"];
    NSString *greenLightPath = [mainBundle pathForResource: @"green" ofType: @"png"];

    redLight = [[NSImage alloc] initWithContentsOfFile:redLightPath];
    greenLight = [[NSImage alloc] initWithContentsOfFile:greenLightPath];
  }

  return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application
}

- (void)awakeFromNib {
  self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  
  self.statusBar.image = redLight;
  self.statusBar.menu = self.statusMenu;
  self.statusBar.highlightMode = YES;
}

- (IBAction)toggleLight:(NSMenuItem *)sender {
  if(lightState == 0) {
    self.statusBar.image = greenLight;
    lightState = 1;
  } else {
    self.statusBar.image = redLight;
    lightState = 0;
  }
}

@end
