//
//  AppDelegate.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [self.controller initFromCache];
}

#pragma mark - notifications

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void) deliverNotificationWithTitle:(NSString*)title subtitle:(NSString*)subtitle message:(NSString*)message andImage:(NSImage*)image {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.subtitle = subtitle;
    notification.informativeText = message;
    notification.contentImage = image;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

@end
