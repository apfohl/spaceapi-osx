//
//  SAPIAppController.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "SAPISpace.h"

@interface SAPIAppController : NSObject

@property (strong) IBOutlet NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *mainMenu;
@property (weak) IBOutlet NSMenu *spacesMenu;
@property (weak) IBOutlet NSMenuItem *selectedSpaceItem;
@property (weak) IBOutlet NSMenuItem *selectedSpaceMessage;

+ (NSDictionary *) dictionaryByReplacingNullsWithStringsInDictionary:(NSDictionary*)dictToClean;

- (IBAction) actionShowPreferencePanel:(NSMenuItem *)sender;
- (IBAction) actionSelectSpaceFromMenu:(NSMenuItem *)sender;
- (IBAction) actionUpdateStatus:(NSMenuItem *)sender;

- (void) startPulseAnimationOnView:(NSView*)view;
- (void) stopPulseAnimationOnView:(NSView*)view;

- (void) fetchSpaceDirectory;

@end
