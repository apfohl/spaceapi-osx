//
//  SpaceAPIAppDelegate.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 07.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SpaceAPIAppDelegate.h"

@implementation SpaceAPIAppDelegate {
  NSImage *redLight;
  NSImage *greenLight;
  NSTimer *stateCheckTimer;
}

- (id)init {
  self = [super init];
  if(self)
  {
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *redLightPath = [mainBundle pathForResource: @"red" ofType: @"png"];
    NSString *greenLightPath = [mainBundle pathForResource: @"green" ofType: @"png"];

    redLight = [[NSImage alloc] initWithContentsOfFile:redLightPath];
    greenLight = [[NSImage alloc] initWithContentsOfFile:greenLightPath];
  }

  return self;
}

- (void)onTick:(NSTimer *)timer {
  [self updateState];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self updateState];
  stateCheckTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(onTick:) userInfo:nil repeats:YES];
}

- (void)awakeFromNib {
  self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  
  self.statusBar.image = redLight;
  self.statusBar.menu = self.statusMenu;
  self.statusBar.highlightMode = YES;
}

- (void)updateState {
  NSURL *spaceApiUrl = [NSURL URLWithString:@"http://spaceapi.n39.eu/json"];
  NSData *apiResponse = [NSData dataWithContentsOfURL:spaceApiUrl];
  NSError *error = nil;

  NSDictionary *apiData = [NSJSONSerialization JSONObjectWithData:apiResponse options:NSJSONReadingMutableContainers error:&error];

  NSNumber *spaceState = [apiData objectForKey:@"open"];
  if ([spaceState boolValue] == YES) {
    self.statusBar.image = greenLight;
  } else {
    self.statusBar.image = redLight;
  }
}

- (IBAction)clickUpdate:(NSMenuItem *)sender {
  [self updateState];
}

@end
