//
//  AppDelegate.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSUserNotificationCenterDelegate>

@property (weak) IBOutlet AppController *controller;

- (void) deliverNotificationWithTitle:(NSString*)title subtitle:(NSString*)subtitle message:(NSString*)message andImage:(NSImage*)image;

@end
