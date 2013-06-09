//
//  SpaceAPIAppDelegate.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 07.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SpaceAPIAppDelegate.h"
#import "Spaces.h"

@interface SpaceAPIAppDelegate ()

@property (nonatomic) NSString *selectedSpace;

@end

@implementation SpaceAPIAppDelegate {
  NSImage *redLight;
  NSImage *greenLight;
  NSImage *blueLight;
  NSTimer *stateCheckTimer;
  Spaces *spaces;
}

- (id)init {
  self = [super init];
  if(self)
  {
    redLight = [NSImage imageNamed:@"red"];
    greenLight = [NSImage imageNamed:@"green"];
    blueLight = [NSImage imageNamed:@"blue"];
    spaces = [[Spaces alloc] init];
  }

  return self;
}

- (void)awakeFromNib {
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

  self.statusItem.image = blueLight;
  self.statusItem.menu = self.statusMenu;
  self.statusItem.highlightMode = YES;
}

- (void)onTick:(NSTimer *)timer {
  [self updateState];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self updateState];
  stateCheckTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(onTick:) userInfo:nil repeats:YES];

  NSArray *spaceNames = [[spaces spaceList] allKeys];
  for (NSString *name in spaceNames) {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = name;
    item.action = @selector(selectSpace:);
    [self.statusMenu insertItem:item atIndex:([self.statusMenu.itemArray count] - 1)];
  }

  if ([self.statusMenu.itemArray count] > 3) {
    [self.statusMenu insertItem:[NSMenuItem separatorItem] atIndex:([self.statusMenu.itemArray count] - 1)];
  }
}

- (void)updateState {
  if (self.selectedSpace) {
    NSString *url = [[spaces spaceList] valueForKey:self.selectedSpace];
    NSURL *spaceApiUrl = [NSURL URLWithString:url];
    NSData *apiResponse = [NSData dataWithContentsOfURL:spaceApiUrl];
    NSError *error = nil;

    NSDictionary *apiData = [NSJSONSerialization JSONObjectWithData:apiResponse options:NSJSONReadingMutableContainers error:&error];

    NSNumber *spaceState = [apiData objectForKey:@"open"];
    if ([spaceState boolValue] == YES) {
      self.statusItem.image = greenLight;
    } else {
      self.statusItem.image = redLight;
    }
  }
}

- (IBAction)clickUpdateState:(NSMenuItem *)sender {
  [self updateState];
}

- (IBAction)selectSpace:(NSMenuItem *)sender {
  self.selectedSpace = [[NSString alloc] initWithString:sender.title];
  self.spaceSelection.title = [NSString stringWithFormat:@"Space: %@", self.selectedSpace];
  for (NSMenuItem *item in self.statusMenu.itemArray){
    [item setState:NSOffState];
  }
  [sender setState:NSOnState];
  [self updateState];
}

@end
