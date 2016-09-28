//
//  AppController.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "AppController.h"
#import "PreferenceController.h"
#import "SAPISpace.h"

@interface AppController ()

@property (nonatomic, strong) PreferenceController *preferenceController;

@end

@implementation AppController {
    NSOperationQueue *_workerQueue;
    NSDictionary *_spacesDirectory;
    SAPISpace *_selectedSpace;
    BOOL inDarkMode;
}

#pragma mark - destruction

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

#pragma mark - sleep/wake detection

- (void) handleSystemSleep:(NSNotification*)notification {
    LOG( @"%s: %@", __PRETTY_FUNCTION__, [notification name] );
}

- (void) handleSystemWake:(NSNotification*)notification {
    LOG( @"%s: %@", __PRETTY_FUNCTION__, [notification name] );
    // REFRESH STATUS AFTER MACHINE WOKE UP
    [self actionUpdateStatus:self];
}

#pragma mark - construction

+ (void)initialize {
    LOG( @"%s", __PRETTY_FUNCTION__ );
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    [defaultValues setObject:[NSNumber numberWithLong:300] forKey:SAPIUpdateIntervalKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (id) init {
    self = [super init];
    if( self ) {
        _workerQueue = [[NSOperationQueue alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenStatusChange:) name:SAPIOpenStatusChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusUpdateFailed:) name:SAPIStatusUpdateFailedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInvalidJsonError:) name:SAPIHasInvalidJsonNotification object:nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                               selector: @selector(handleSystemSleep:)
                                                                   name: NSWorkspaceWillSleepNotification object: NULL];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                               selector: @selector(handleSystemWake:)
                                                                   name: NSWorkspaceDidWakeNotification object: NULL];
    }
    return self;
}

- (void) awakeFromNib {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.wantsLayer = YES;
    self.statusItem.image = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.alternateImage = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.menu = self.mainMenu;
    self.statusItem.highlightMode = YES;
    inDarkMode = [[[NSAppearance currentAppearance] name] containsString:NSAppearanceNameVibrantDark];
    [self updateVersionMenu];
}

#pragma mark - convenience

+ (id) dictionaryByReplacingNullsWithStringsInDictionary:(NSDictionary*)dictToClean {
    if( ![[dictToClean class] isSubclassOfClass:[NSDictionary class]] ) {
        if( [NSStringFromClass( [dictToClean class] ) isEqualToString:@"NSTaggedPointerString"] ) {
            NSString *taggedString = (NSString*)dictToClean;
            return [taggedString componentsSeparatedByString:@","];
        }
        else {
            LOG( @"WARNING: EXPECTED DICTIONARY IS ACTUALLY INSTANCE OF: '%@'.", NSStringFromClass( [dictToClean class] ) );
            LOG( @"WARNING: CONTENT IS:\n---\n%@\n---\n\n", dictToClean );
            return dictToClean;
        }
    }
    NSMutableDictionary *replaced = [NSMutableDictionary dictionaryWithDictionary:dictToClean];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    
    for( NSString *currentKey in dictToClean ) {
        id currentObject = [dictToClean objectForKey:currentKey];
        if( currentObject == nul ) {
            LOG( @"WARNING: KEY '%@' WAS CONTAINING <null>-VALUE.", currentKey );
            LOG( @"WARNING: BELONGED TO DICTIONARY '%@'.", dictToClean );
            [replaced setObject:blank forKey:currentKey];
        }
        else if( [currentObject isKindOfClass:[NSDictionary class]] ) {
            [replaced setObject:[self dictionaryByReplacingNullsWithStringsInDictionary:currentObject] forKey:currentKey];
        }
        else if( [currentObject isKindOfClass:[NSArray class]] ) {
            NSMutableArray *replacedArray = [NSMutableArray array];
            for( NSDictionary* currentArrayItem in currentObject ) {
                [replacedArray addObject:[self dictionaryByReplacingNullsWithStringsInDictionary:currentArrayItem]];
            }
            [replaced setObject:[NSArray arrayWithArray:replacedArray] forKey:currentKey];
        }
    }
    return [NSDictionary dictionaryWithDictionary:replaced];
}

- (PreferenceController *)preferenceController {
    if (!_preferenceController) {
        _preferenceController = [[PreferenceController alloc] init];
    }
    return _preferenceController;
}

- (NSImage*) imageForStatus:(SpaceStatus)status {
    switch( status ) {
        case SpaceStatusUnknown:
            return [NSImage imageNamed:inDarkMode ? @"unknown_dark" : @"unknown"];
            break;
        case SpaceStatusJsonBug:
            return [NSImage imageNamed:inDarkMode ? @"bug" : @"bug"];
            break;
        case SpaceStatusOpen:
            return [NSImage imageNamed:inDarkMode ? @"open_dark" : @"open"];
            break;
        case SpaceStatusClosed:
            return [NSImage imageNamed:inDarkMode ? @"closed_dark" : @"closed"];
            break;
            
        default:
            break;
    }
}

- (void) updateMenuItemEnabled:(BOOL)enabled containingString:(NSString*)stringSearch withString:(NSString*)stringTitle {
    for( NSMenuItem *currentItem in self.mainMenu.itemArray ) {
        if( [currentItem.title rangeOfString:stringSearch].location != NSNotFound ) {
            [currentItem setTitle:stringTitle];
            [currentItem setEnabled:enabled];
        }
    }
}

- (void) updateVersionMenu {
    NSString *appShortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *appBuildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *appVersion = [NSString stringWithFormat:@"Version %@ (Build %@)", appShortVersion, appBuildNumber];
    [self updateMenuItemEnabled:NO containingString:@"Version" withString:appVersion];
}

- (void) updateHackerspaceMenu {
    NSUInteger amountOfSpaces = [self.spacesMenu.itemArray count];
    NSString *spacesTitle = [NSString stringWithFormat:@"Hackerspaces (%lu)", amountOfSpaces];
    [self updateMenuItemEnabled:YES containingString:@"Hackerspaces" withString:spacesTitle];
}

- (void) selectSpace:(NSString *)name {
    [_selectedSpace timerCancel];
    _selectedSpace = [[SAPISpace alloc] initWithName:name andAPIURL:[_spacesDirectory objectForKey:name]];
    [self actionUpdateStatus:self];
    self.selectedSpaceItem.title = [NSString stringWithFormat:LOC( @"Space: %@" ), _selectedSpace.name];
    [PreferenceController setSelectedSpace:_selectedSpace.name];
    NSArray *spaceEntries = self.spacesMenu.itemArray;
    for( NSMenuItem *currentItem in spaceEntries ) {
        if( [currentItem.title isEqualToString:_selectedSpace.name] ) {
            [currentItem setState:1]; // ADDS CHECKMARK IN MENU
        }
        else {
            [currentItem setState:0];
        }
    }
    [self updateHackerspaceMenu];
}

#pragma mark - notifications

- (void) handleInvalidJsonError:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = [notification userInfo];
        [self stopPulseAnimationOnView:self.statusItem.button];
        self.statusItem.image = [self imageForStatus:SpaceStatusJsonBug];
        self.statusItem.alternateImage = [self imageForStatus:SpaceStatusJsonBug];
        self.selectedSpaceMessage.title = [NSString stringWithFormat:@"ERROR:\n%@", [userInfo objectForKey:@"error"]];
        self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
        self.selectedSpaceMessage.hidden = NO;
        LOG( @"\n*** FATAL-API-FAIL ***\n\n  API: %@\n  URL: %@\nERROR: %@\n JSON: %@\n", [userInfo objectForKey:@"apicall"],[userInfo objectForKey:@"url"], [userInfo objectForKey:@"error"], [userInfo objectForKey:@"json"]);
    });
}

- (void) handleStatusUpdateFailed:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPulseAnimationOnView:self.statusItem.button];
    });
}

- (void) handleOpenStatusChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPulseAnimationOnView:self.statusItem.button];
        @try {
            BOOL isStatusOpen = [[[notification userInfo] objectForKey:@"openStatus"] boolValue];
            self.statusItem.image = [self imageForStatus:isStatusOpen ? SpaceStatusOpen : SpaceStatusClosed];
            self.statusItem.alternateImage = [self imageForStatus:isStatusOpen ? SpaceStatusOpen : SpaceStatusClosed];
            NSString *statusMessage = [[notification userInfo] objectForKey:@"statusMessage"];
            self.selectedSpaceMessage.title = statusMessage ?: LOC( @"Space: no message" );
            self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
            self.selectedSpaceMessage.hidden = ( statusMessage == nil );
        }
        @catch (NSException *exception) {
            LOG( @"handleOpenStatusChange Error: %@\n\n---\n%@", [notification userInfo], exception );
            self.statusItem.image = [self imageForStatus:SpaceStatusJsonBug];
            self.statusItem.alternateImage = [self imageForStatus:SpaceStatusJsonBug];
            self.selectedSpaceMessage.title = [NSString stringWithFormat:@"BUG IN JSON:\n%@\nEXCEPTION:%@\n", [notification userInfo], exception];
            self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
            self.selectedSpaceMessage.hidden = NO;
        }
    });
}

- (void) fetchSpaceDirectory {
    NSURL *spaceAPIDirectoryUrl = [NSURL URLWithString:@"http://spaceapi.net/directory.json"];
    NSURLRequest *spaceAPIDirectoryRequest = [[NSURLRequest alloc] initWithURL:spaceAPIDirectoryUrl];
    [NSURLConnection sendAsynchronousRequest:spaceAPIDirectoryRequest queue:_workerQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if( data && !error ) {
            NSError *jsonError;
            NSString *jsonRawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            _spacesDirectory = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            if( !jsonError ) {
                @try {
                    // SANITIZE DATA...
                    _spacesDirectory = [AppController dictionaryByReplacingNullsWithStringsInDictionary:_spacesDirectory];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                        [self.spacesMenu removeItemAtIndex:0];
                    }];
                    
                    NSMenuItem *currentSpaceItem = nil;
                    for (NSString *name in [[_spacesDirectory allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
                        currentSpaceItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(actionSelectSpaceFromMenu:) keyEquivalent:@""];
                        currentSpaceItem.target = self;
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                            [self.spacesMenu addItem:currentSpaceItem];
                        }];
                    }

                    NSString *spaceName = [PreferenceController selectedSpace];
                    if( spaceName ) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                            [self selectSpace:spaceName];
                        }];
                    }
                }
                @catch (NSException *exception) {
                    LOG( @"fetchSpaceDirectory Error decoding JSON: %@\n\n---\n%@", _spacesDirectory, exception );
                    self.statusItem.image = [self imageForStatus:SpaceStatusJsonBug];
                    self.statusItem.alternateImage = [self imageForStatus:SpaceStatusJsonBug];
                    self.selectedSpaceMessage.title = [NSString stringWithFormat:@"BUG IN JSON:\n%@\nEXCEPTION:%@\n", _spacesDirectory, exception];
                    self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
                    self.selectedSpaceMessage.hidden = NO;
                }
            }
            else {
                if( !jsonRawString ) {
                    jsonRawString = @"[NIL]";
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:SAPIHasInvalidJsonNotification object:self userInfo:@{@"error":jsonError, @"json":jsonRawString,@"apicall":@"spacedirectory",@"url":[spaceAPIDirectoryUrl absoluteString]}];
            }
        }
    }];
}

#pragma mark - animations

- (void) startPulseAnimationOnView:(NSView*)view {
    if( [view.layer.animationKeys count] > 0 ) return;
    @synchronized (view.layer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.duration = 0.5;
            animation.repeatCount = HUGE_VALF;
            animation.autoreverses = YES;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            animation.fromValue = [NSNumber numberWithFloat:0.15];
            animation.toValue = [NSNumber numberWithFloat:1.0];
            [CATransaction begin];
            [view.layer removeAllAnimations];
            [CATransaction commit];
            [CATransaction begin];
            [view.layer addAnimation:animation forKey:@"animateSlowFlashing"];
            [CATransaction commit];
        });
    }
}

- (void) stopPulseAnimationOnView:(NSView*)view {
    if( [view.layer.animationKeys count] == 0 ) return;
    @synchronized (view.layer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CATransaction begin];
            [view.layer removeAllAnimations];
            [CATransaction commit];
        });
    }
}

#pragma mark - user actions

- (IBAction) actionShowPreferencePanel:(id)sender {
    [self.preferenceController showWindow:self];
}

- (IBAction) actionSelectSpaceFromMenu:(NSMenuItem *)sender {
    self.statusItem.image = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.alternateImage = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.button.toolTip = LOC( @"Space: no message" );
    self.selectedSpaceMessage.title = LOC( @"Space: no message" );
    self.selectedSpaceMessage.hidden = YES;
    [self startPulseAnimationOnView:self.statusItem.button];
    [self selectSpace:sender.title];
}

- (IBAction) actionUpdateStatus:(id)sender {
    self.statusItem.image = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.alternateImage = [self imageForStatus:SpaceStatusUnknown];
    [self startPulseAnimationOnView:self.statusItem.button];
    [_selectedSpace fetchSpaceStatus];
}


@end
