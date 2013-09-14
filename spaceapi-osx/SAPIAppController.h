//
//  SAPIAppController.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SAPIAppController : NSObject

@property (strong) IBOutlet NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *mainMenu;
@property (weak) IBOutlet NSMenu *spacesMenu;
@property (weak) IBOutlet NSMenuItem *selectedSpaceItem;

- (IBAction)showPreferencePanel:(NSMenuItem *)sender;
- (IBAction)selectSpaceFromMenu:(NSMenuItem *)sender;

- (void)fetchSpaceDirectory;

@end
