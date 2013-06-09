//
//  SpaceAPIAppDelegate.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 07.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SpaceAPIAppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSStatusItem *statusItem;

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;

@property (strong) IBOutlet NSMenuItem *spaceSelection;

- (IBAction)clickUpdateState:(NSMenuItem *)sender;

@end
