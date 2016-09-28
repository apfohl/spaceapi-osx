//
//  AppController.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "SAPISpace.h"

typedef enum {
    SpaceStatusZero     = 0,
    SpaceStatusUnknown  = 1,
    SpaceStatusJsonBug  = 2,
    SpaceStatusOpen     = 3,
    SpaceStatusClosed   = 4,
} SpaceStatus;

@interface AppController : NSObject

@property (strong) IBOutlet NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *mainMenu;
@property (weak) IBOutlet NSMenu *spacesMenu;
@property (weak) IBOutlet NSMenuItem *selectedSpaceItem;
@property (weak) IBOutlet NSMenuItem *selectedSpaceMessage;
@property (assign) SpaceStatus latestStatus;
@property (strong) NSString *latestSpaceStatusMessage;

+ (NSDictionary *) dictionaryByReplacingNullsWithStringsInDictionary:(NSDictionary*)dictToClean;

- (IBAction) actionShowPreferencePanel:(NSMenuItem *)sender;
- (IBAction) actionSelectSpaceFromMenu:(NSMenuItem *)sender;
- (IBAction) actionUpdateStatus:(id)sender;

- (void) startPulseAnimationOnView:(NSView*)view;
- (void) stopPulseAnimationOnView:(NSView*)view;

- (void) fetchSpaceDirectory;

@end
