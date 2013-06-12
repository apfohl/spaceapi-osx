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

@property (nonatomic, strong) NSUserDefaults *preferences;

@property (strong) NSStatusItem *statusItem;
@property (strong) IBOutlet NSMenu *statusMenu;

@property (nonatomic, strong) NSImage *yellowLight;
@property (nonatomic, strong) NSImage *redLight;
@property (nonatomic, strong) NSImage *greenLight;

@property (strong) IBOutlet NSMenuItem *spaceSelection;
@property (strong) NSString *selectedSpace;

@property (nonatomic, strong) Statuses *status;
@property (nonatomic, strong) NSTimer *statusCheckTimer;

@end

@implementation SpaceAPIController

- (id)init {
  self = [super init];
  if (self) {
    self.selectedSpace = [[self preferences] objectForKey:@"selectedSpace"];
  }
  return self;
}

- (NSUserDefaults *)preferences
{
  if (!_preferences) {
    _preferences = [NSUserDefaults standardUserDefaults];
  }
  return _preferences;
}

- (NSImage *)yellowLight {
  if (!_yellowLight) {
    _yellowLight = [NSImage imageNamed:@"yellow"];
  }
  return _yellowLight;
}

- (NSImage *)redLight {
  if (!_redLight) {
    _redLight = [NSImage imageNamed:@"red"];
  }
  return _redLight;
}

- (NSImage *)greenLight {
  if (!_greenLight) {
    _greenLight = [NSImage imageNamed:@"green"];
  }
  return _greenLight;
}

- (Statuses *)status {
  if (!_status) {
    _status = [[Statuses alloc] init];
  }
  return _status;
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
  self.statusItem.image = [self yellowLight];
  self.statusItem.menu = self.statusMenu;
  self.statusItem.highlightMode = YES;

  NSArray *spaceNames = [[self status] getSpaceList];
  for (NSString *name in spaceNames) {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = name;
    item.image = [self yellowLight];
    item.action = @selector(selectSpace:);
    item.target = self;
    [self.statusMenu addItem:item];
  }

  if ([self.statusMenu.itemArray count] > 7) {
    [self.statusMenu removeItemAtIndex:6];
  }

  if (self.selectedSpace) {
    [self updateStatus];
    [self statusCheckTimer];
    self.spaceSelection.title = [NSString stringWithFormat:@"Space: %@", self.selectedSpace];
  }
}

- (IBAction)clickUpdateStatus:(NSMenuItem *)sender {
  [self updateStatus];
}

- (IBAction)selectSpace:(NSMenuItem *)sender {
  self.selectedSpace = [[NSString alloc] initWithString:sender.title];
  self.spaceSelection.title = [NSString stringWithFormat:@"Space: %@", self.selectedSpace];

  for (NSMenuItem *item in self.statusMenu.itemArray) {
    [item setState:NSOffState];
  }
  [sender setState:NSOnState];

  [self updateStatus];
  [self statusCheckTimer];
  [[self preferences] setObject:self.selectedSpace forKey:@"selectedSpace"];
}

- (void)updateStatus {
  if (self.selectedSpace) {
    if ([[self status] isOpen:self.selectedSpace] == YES) {
      self.statusItem.image = [self greenLight];
    } else {
      self.statusItem.image = [self redLight];
    }
  }
}

@end
