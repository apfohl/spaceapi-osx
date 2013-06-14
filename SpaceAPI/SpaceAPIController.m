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

@end

@implementation SpaceAPIController {
  NSOperationQueue *renderQueue;
  NSOperationQueue *fetchQueue;
}

- (id)init {
  self = [super init];
  if (self) {
    renderQueue = [[NSOperationQueue alloc] init];
    fetchQueue = [[NSOperationQueue alloc] init];
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

- (void)awakeFromNib {
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  self.statusItem.image = self.yellowLight;
  self.statusItem.menu = self.mainMenu;
  self.statusItem.highlightMode = YES;

  self.spaces.submenu = self.spaceList;

  [fetchQueue addOperationWithBlock:^(void) {
    NSURL *spaceAPIDirectoryUrl = [NSURL URLWithString:@"http://spaceapi.net/directory.json"];
    NSURLRequest *spaceAPIDirectoryRequest = [[NSURLRequest alloc] initWithURL:spaceAPIDirectoryUrl];
    [NSURLConnection sendAsynchronousRequest:spaceAPIDirectoryRequest queue:renderQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
      if (data && !error) {
        self.spacesDirectory = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        for (NSString *name in [[self.spacesDirectory allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
          NSMenuItem *spaceItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(selectSpace:) keyEquivalent:@""];
          spaceItem.target = self;
          spaceItem.image = self.yellowLight;

          [self updateSpaceStatusWith:spaceItem];
          [self.spaceList addItem:spaceItem];
        }
      }
    }];
  }];
}

- (void)updateSpaceStatusWith:(NSMenuItem *)menuItem {
  [fetchQueue addOperationWithBlock:^(void) {
    NSURL *spaceAPIUrl = [NSURL URLWithString:[self.spacesDirectory objectForKey:menuItem.title]];
    NSURLRequest *spaceAPIRequest = [[NSURLRequest alloc] initWithURL:spaceAPIUrl];
    [NSURLConnection sendAsynchronousRequest:spaceAPIRequest queue:renderQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
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

          if ([openStatus boolValue]) {
            menuItem.image = self.greenLight;
          } else {
            menuItem.image = self.redLight;
          }
        }
      }
    }];
  }];
}

- (IBAction)selectSpace:(NSMenuItem *)sender {
  NSLog(@"%@", sender.title);
}

@end
