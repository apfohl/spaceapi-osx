//
//  SpaceAPIController.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 09.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SpaceAPIController : NSObjectController

@property (strong) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *mainMenu;
@property (weak) IBOutlet NSMenuItem *spaces;
@property (weak) IBOutlet NSMenuItem *spaceSelection;

- (IBAction)selectSpace:(NSMenuItem *)sender;
- (IBAction)pressUpdateStatus:(NSMenuItem *)sender;
- (void)updateSpaceDirectory;

@end
