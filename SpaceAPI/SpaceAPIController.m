//
//  SpaceAPIController.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 09.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SpaceAPIController.h"
#import "Spaces.h"
#import "Statuses.h"

@interface SpaceAPIController ()

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;

@property (strong, nonatomic) NSImage *blueLight;
@property (strong, nonatomic) NSImage *redLight;
@property (strong, nonatomic) NSImage *greenLight;

@property (strong, nonatomic) Spaces *spaces;
@property (strong, nonatomic) IBOutlet NSMenuItem *spaceSelection;
@property (strong, nonatomic) NSString *selectedSpace;

@property (strong, nonatomic) Statuses *status;
@property (strong, nonatomic) NSTimer *statusCheckTimer;

@end

@implementation SpaceAPIController

- (NSImage *)blueLight {
  if(!_blueLight) {
    _blueLight = [NSImage imageNamed:@"blue"];
  }
  return _blueLight;
}

- (NSImage *)redLight {
  if(!_redLight) {
    _redLight = [NSImage imageNamed:@"red"];
  }
  return _redLight;
}

- (NSImage *)greenLight {
  if(!_greenLight) {
    _greenLight = [NSImage imageNamed:@"green"];
  }
  return _greenLight;
}

- (Spaces *)spaces {
  if(!_spaces) {
    _spaces = [[Spaces alloc] init];
  }
  return _spaces;
}

- (NSTimer *)statusCheckTimer {
  if(!_statusCheckTimer) {
    _statusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(onTick:) userInfo:nil repeats:YES];
  }
  return _statusCheckTimer;
}

- (void)onTick:(NSTimer *)timer {
  [self updateStatus];
}

- (void)awakeFromNib {
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  self.statusItem.image = [self blueLight];
  self.statusItem.menu = self.statusMenu;
  self.statusItem.highlightMode = YES;

  NSArray *spaceNames = [[[self.spaces spaceList] allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
  for (NSString *name in spaceNames) {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = name;
    item.action = @selector(selectSpace:);
    item.target = self;
    [self.statusMenu addItem:item];
  }

  if ([self.statusMenu.itemArray count] > 6) {
    [self.statusMenu removeItemAtIndex:5];
  }
}

- (IBAction)clickUpdateStatus:(NSMenuItem *)sender {
  [self updateStatus];
}

- (IBAction)selectSpace:(NSMenuItem *)sender {
  self.selectedSpace = [[NSString alloc] initWithString:sender.title];
  self.spaceSelection.title = [NSString stringWithFormat:@"Space: %@", self.selectedSpace];
  
  for (NSMenuItem *item in self.statusMenu.itemArray){
    [item setState:NSOffState];
  }
  
  [sender setState:NSOnState];
  [self updateStatus];
  [self statusCheckTimer];
}

- (void)updateStatus {
  if (self.selectedSpace) {
    NSString *url = [[self.spaces spaceList] valueForKey:self.selectedSpace];
    NSURL *spaceApiUrl = [NSURL URLWithString:url];
    NSData *apiResponse = [NSData dataWithContentsOfURL:spaceApiUrl];
    NSError *error = nil;

    NSDictionary *apiData = [NSJSONSerialization JSONObjectWithData:apiResponse options:NSJSONReadingMutableContainers error:&error];

    NSNumber *spaceState = [apiData objectForKey:@"open"];
    if ([spaceState boolValue] == YES) {
      self.statusItem.image = [self greenLight];
    } else {
      self.statusItem.image = [self redLight];
    }
  }
}

@end
