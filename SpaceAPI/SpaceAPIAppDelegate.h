//
//  SpaceAPIAppDelegate.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 07.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SpaceAPIAppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSMenu *statusMenu;

@property (strong, nonatomic) NSStatusItem *statusBar;

- (id)init;

- (IBAction)clickUpdate:(NSMenuItem *)sender;

@end
