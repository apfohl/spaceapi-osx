//
//  SpaceAPIController.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 09.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SpaceAPIController.h"

@interface SpaceAPIController ()

@property (nonatomic, strong) NSUserDefaults *preferences;

@property (nonatomic, strong) NSImage *yellowLight;
@property (nonatomic, strong) NSImage *redLight;
@property (nonatomic, strong) NSImage *greenLight;

@property (nonatomic, strong) NSMenu *spaceList;
@property (nonatomic, strong) NSDictionary *spacesDirectory;

@property (nonatomic, strong) NSTimer *statusCheckTimer;

@end

@implementation SpaceAPIController {
  NSOperationQueue *_workerQueue;
  NSString *_selectedSpace;
}

- (id)init {
  self = [super init];
  if (self) {
    _workerQueue = [[NSOperationQueue alloc] init];
    _selectedSpace = [self.preferences objectForKey:@"selectedSpace"];
  }
  return self;
}

- (NSUserDefaults *)preferences {
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

- (NSMenu *)spaceList {
  if (!_spaceList) {
    _spaceList = [[NSMenu alloc] init];
  }
  return _spaceList;
}

- (NSTimer *)statusCheckTimer {
  if (!_statusCheckTimer) {
    _statusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(checkStatus:) userInfo:nil repeats:YES];
  }
  return _statusCheckTimer;
}

- (IBAction)checkStatus:(id)sender {
  [self updateSelectedSpace];
}

- (void)awakeFromNib {
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  self.statusItem.image = self.yellowLight;
  self.statusItem.menu = self.mainMenu;
  self.statusItem.highlightMode = YES;

  self.spaces.submenu = self.spaceList;
  if (_selectedSpace) {
    self.spaceSelection.title = [[NSString alloc] initWithFormat:@"Space: %@", _selectedSpace];
    [self statusCheckTimer];
  }
}

- (void)updateSpaceDirectory {
  NSURL *spaceAPIDirectoryUrl = [NSURL URLWithString:@"http://spaceapi.net/directory.json"];
  NSURLRequest *spaceAPIDirectoryRequest = [[NSURLRequest alloc] initWithURL:spaceAPIDirectoryUrl];
  [NSURLConnection sendAsynchronousRequest:spaceAPIDirectoryRequest queue:_workerQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    if (data && !error) {
      self.spacesDirectory = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

      [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
        [self updateSelectedSpace];
      }];

      for (NSString *name in [[self.spacesDirectory allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        NSMenuItem *spaceItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(selectSpace:) keyEquivalent:@""];
        spaceItem.target = self;
        spaceItem.image = self.yellowLight;

        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
          [self updateSpaceStatusWith:spaceItem];
          [self.spaceList addItem:spaceItem];
        }];
      }
    }
  }];
}

- (void)updateSpaceStatusWith:(id)object {
  NSURL *spaceAPIUrl;
  
  if ([object isKindOfClass:[NSMenuItem class]]) {
    spaceAPIUrl = [NSURL URLWithString:[self.spacesDirectory objectForKey:((NSMenuItem *)object).title]];
  } else if ([object isKindOfClass:[NSStatusItem class]]) {
    spaceAPIUrl = [NSURL URLWithString:[self.spacesDirectory objectForKey:_selectedSpace]];
  }

  NSURLRequest *spaceAPIRequest = [[NSURLRequest alloc] initWithURL:spaceAPIUrl];
  [NSURLConnection sendAsynchronousRequest:spaceAPIRequest queue:_workerQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    if (data && !error) {
      NSError *jsonError;
      NSDictionary *spaceData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

      if (!jsonError) {
        NSNumber *openStatus;
        NSString *version = [[NSString alloc] initWithFormat:@"%@", [spaceData objectForKey:@"api"]];;
        if ([version isEqualToString:@"0.11"] || [version isEqualToString:@"0.12"]) {
          openStatus = [spaceData objectForKey:@"open"];
        } else if ([version isEqualToString:@"0.13"]) {
          openStatus = [[spaceData objectForKey:@"state"] objectForKey:@"open"];
        }

        if ([object isKindOfClass:[NSMenuItem class]]) {
          ((NSMenuItem *)object).image = [openStatus boolValue] ? self.greenLight : self.redLight;
        } else if ([object isKindOfClass:[NSStatusItem class]]) {
          ((NSStatusItem *)object).image = [openStatus boolValue] ? self.greenLight : self.redLight;
        }
      }
    }
  }];
}

- (void)updateSelectedSpace {
  [self updateSpaceStatusWith:self.statusItem];
}

- (IBAction)pressUpdateStatus:(NSMenuItem *)sender {
  [self updateSelectedSpace];
}

- (IBAction)selectSpace:(NSMenuItem *)sender {
  _selectedSpace = sender.title;
  [self.preferences setObject:[[NSString alloc] initWithFormat:@"%@", _selectedSpace] forKey:@"selectedSpace"];

  self.spaceSelection.title = [[NSString alloc] initWithFormat:@"Space: %@", _selectedSpace];
  [self updateSpaceStatusWith:self.statusItem];
  [self statusCheckTimer];
}

@end
