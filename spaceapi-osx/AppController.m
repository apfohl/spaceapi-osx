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
#import "AppDelegate.h"

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
    self.latestStatus = SpaceStatusZero;
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

- (AppDelegate*)appDelegate {
    return (AppDelegate*)[NSApplication sharedApplication].delegate;
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
        case SpaceStatusZero:
            return [NSImage imageNamed:inDarkMode ? @"unknown_dark" : @"unknown"];
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

#pragma mark - get users attention

- (void) playAudioAlert {
    NSSound *sound = nil;
    @try {
        sound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"alarm" ofType:@"caf"] byReference:NO];
        [sound play];
    }
    @catch (NSException *exception) {
        // do nothing
    }
}

- (void) notifyUserStatusChangedWithMessage:(NSString*)message {
    NSString *statusAsText = nil;
    if( self.latestStatus == SpaceStatusClosed ) {
        statusAsText = LOC( @"Is now closed." );
    }
    else if( self.latestStatus == SpaceStatusOpen ) {
        statusAsText = LOC( @"Is now open." );
    }
    else if( self.latestStatus == SpaceStatusJsonBug ) {
        statusAsText = LOC( @"Error in spaceAPI." );
    }
    else {
        return; // do nothing for other statuses
    }
    NSString *title = _selectedSpace ? _selectedSpace.name : LOC( @"Status changed" );
    [[self appDelegate] deliverNotificationWithTitle:title subtitle:statusAsText message:message andImage:[self imageForStatus:_latestStatus]];
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
        if( self.latestStatus != SpaceStatusJsonBug ) {
            self.latestStatus = SpaceStatusJsonBug;
            self.latestSpaceStatusMessage = self.selectedSpaceMessage.title;
            [self notifyUserStatusChangedWithMessage:self.selectedSpaceMessage.title];
        }
    });
}

- (void) handleStatusUpdateFailed:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPulseAnimationOnView:self.statusItem.button];
        if( self.latestStatus != SpaceStatusUnknown ) {
            self.latestStatus = SpaceStatusUnknown;
            self.latestSpaceStatusMessage = nil;
        }
    });
}

- (void) handleOpenStatusChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPulseAnimationOnView:self.statusItem.button];
        @try {
            NSString *statusMessage = [[notification userInfo] objectForKey:@"statusMessage"];
            BOOL isStatusOpen = [[[notification userInfo] objectForKey:@"openStatus"] boolValue];
            
            SpaceStatus statusUpdated = isStatusOpen ? SpaceStatusOpen : SpaceStatusClosed;
            BOOL shouldNotifyUser = DEBUG_FORCE_NOTIFICATION;
            if( self.latestStatus == SpaceStatusZero || self.latestStatus == SpaceStatusUnknown ) {
                // INITIAL SET OF STATUS
                self.latestSpaceStatusMessage = statusMessage;
            }
            if( self.latestStatus != statusUpdated && ( (self.latestStatus == SpaceStatusOpen) | (self.latestStatus == SpaceStatusClosed) ) ) {
                self.latestSpaceStatusMessage = statusMessage;
                shouldNotifyUser = YES; // BECAUSE STATUS CHANGED
            }
            else {
                // NOTIFY USER WHEN STATUS MESSAGE CHANGES (EVEN IF STATUS ITSELF STAYS THE SAME)
                if( ![statusMessage isEqualToString:self.latestSpaceStatusMessage] ) {
                    shouldNotifyUser = YES; // BECAUSE STATUS MESSAGE WAS CHANGED
                    self.latestSpaceStatusMessage = statusMessage;
                }
            }
            self.latestStatus = isStatusOpen ? SpaceStatusOpen : SpaceStatusClosed;
            self.statusItem.image = [self imageForStatus:isStatusOpen ? SpaceStatusOpen : SpaceStatusClosed];
            self.statusItem.alternateImage = [self imageForStatus:isStatusOpen ? SpaceStatusOpen : SpaceStatusClosed];
            self.selectedSpaceMessage.title = statusMessage ?: LOC( @"Space: no message" );
            self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
            self.selectedSpaceMessage.hidden = ( statusMessage == nil );
            if( shouldNotifyUser ) {
                [self notifyUserStatusChangedWithMessage:statusMessage];
            }
        }
        @catch (NSException *exception) {
            LOG( @"handleOpenStatusChange Error: %@\n\n---\n%@", [notification userInfo], exception );
            self.latestStatus = SpaceStatusJsonBug;
            self.statusItem.image = [self imageForStatus:SpaceStatusJsonBug];
            self.statusItem.alternateImage = [self imageForStatus:SpaceStatusJsonBug];
            self.selectedSpaceMessage.title = [NSString stringWithFormat:@"BUG IN JSON:\n%@\nEXCEPTION:%@\n", [notification userInfo], exception];
            self.latestSpaceStatusMessage = self.selectedSpaceMessage.title;
            self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
            self.selectedSpaceMessage.hidden = NO;
        }
    });
}

- (void) alertFailedToFetchDirectory {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:LOC( @"OK" )];
        [alert addButtonWithTitle:LOC( @"Try again..." )];
        [alert setMessageText:LOC( @"Error fetching Hackerspaces" )];
        [alert setInformativeText:LOC( @"The server providing the directory of spaceAPI listed Hackerspaces did not deliver expected data." )];
        [alert setAlertStyle:NSWarningAlertStyle];
        NSUInteger buttonIndex = [alert runModal];
        if( buttonIndex == NSAlertFirstButtonReturn ) {
            // OK clicked
        }
        else if( buttonIndex == NSAlertSecondButtonReturn ) {
            [self fetchSpaceDirectory];
        }
    });
}

- (void) fetchSpaceDirectory {
    NSURL *spaceAPIDirectoryUrl = [NSURL URLWithString:kURL_SPACE_DIRECTORY];
    NSURLRequest *spaceAPIDirectoryRequest = [[NSURLRequest alloc] initWithURL:spaceAPIDirectoryUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];

    [NSURLConnection sendAsynchronousRequest:spaceAPIDirectoryRequest queue:_workerQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if( data && !error ) {
            NSError *jsonError;
            NSString *jsonRawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            if( !jsonError ) {
                @try {
                    // SANITIZE DATA...
                    tempDict = [AppController dictionaryByReplacingNullsWithStringsInDictionary:tempDict];
                    // TODO: save the dictionary a PLIST-cache file
                    [self cacheSaveDirectoryIfValid:tempDict];
                    
                    [self updateSpacesMenu];
                    
                    [self selectSpaceFromCache];
                }
                @catch (NSException *exception) {
                    LOG( @"fetchSpaceDirectory Error decoding JSON: %@\n\n---\n%@", tempDict, exception );
                    self.statusItem.image = [self imageForStatus:SpaceStatusJsonBug];
                    self.statusItem.alternateImage = [self imageForStatus:SpaceStatusJsonBug];
                    self.selectedSpaceMessage.title = [NSString stringWithFormat:@"BUG IN JSON:\n%@\nEXCEPTION:%@\n", tempDict, exception];
                    self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
                    self.selectedSpaceMessage.hidden = NO;
                }
            }
            else {
                // WILL NOT REPLACE CACHE OF DIRECTORY, BUT INSTEAD SPIT OUT ERROR ALERT
                LOG( @"JSON ERROR, WHILE FETCHING DIRECTORY." );
                if( !jsonRawString ) {
                    jsonRawString = @"[NIL]";
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:SAPIHasInvalidJsonNotification object:self userInfo:@{@"error":jsonError, @"json":jsonRawString,@"apicall":@"spacedirectory",@"url":[spaceAPIDirectoryUrl absoluteString]}];
                
                // ALERT
                [self alertFailedToFetchDirectory];
            }
        }
        else {
            LOG( @"FAILED TO CONNECT TO... %@", kURL_SPACE_DIRECTORY );
            [self alertFailedToFetchDirectory];
        }
    }];
}

#pragma mark - manage cached data

- (void) initFromCache {
    // INIT SPACE DIRECTORY WITH A CACHED VERSION FROM BUNDLE IF NECESSARY...
    LOG( @"CACHE LOCATION: %@", [self cachePathDirectory] );
    
    if( ![self hasCachedDirectory] ) {
        LOG( @"INIT FROM BUNDLE CACHE: %@", [self bundlePathDirectory] );
        NSDictionary *spaces = [self cacheLoadDirectoryFromPath:[self bundlePathDirectory]];
        [self cacheSaveDirectory:spaces];
    }
    [self updateSpacesMenu];
    [self selectSpaceFromCache];
    [self performSelector:@selector(fetchSpaceDirectory) withObject:nil afterDelay:2.0];
}

- (void) updateSpacesMenu {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
        [self.spacesMenu removeAllItems];
    }];
    
    _spacesDirectory = [self cacheLoadDirectoryFromPath:[self cachePathDirectory]];
    NSMenuItem *currentSpaceItem = nil;
    for (NSString *name in [[_spacesDirectory allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        currentSpaceItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(actionSelectSpaceFromMenu:) keyEquivalent:@""];
        currentSpaceItem.target = self;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            [self.spacesMenu addItem:currentSpaceItem];
        }];
    }
}

- (void) selectSpaceFromCache {
    NSString *spaceName = [PreferenceController selectedSpace];
    if( spaceName ) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            [self selectSpace:spaceName];
        }];
    }
}

- (NSString*)bundlePathDirectory {
    return [[NSBundle mainBundle] pathForResource:kCACHE_DIRECTORY_NAME ofType:kCACHE_SUFFIX];
}

- (NSString*)cachePathDirectory {
    NSString *cachesDirectory = USER_CACHES_FOLDER;
    NSString *cacheFileName = [NSString stringWithFormat:@"%@.%@", kCACHE_DIRECTORY_NAME, kCACHE_SUFFIX];
    return [cachesDirectory stringByAppendingPathComponent:cacheFileName];
}

- (BOOL) hasCachedDirectory {
    NSString *path = [self cachePathDirectory];
    BOOL hasFile = NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    @try {
        hasFile = [fm fileExistsAtPath:path];
    }
    @catch (NSException *exception) {
        LOG( @"%@", exception );
        hasFile = NO;
    }
    return hasFile;
}

- (NSDictionary*) cacheLoadDirectoryFromPath:(NSString*)path {
    LOG( @"CACHE: LOADING..." );
    NSDictionary *loadedDict = nil;
    @try {
        loadedDict = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    @catch (NSException *exception) {
        LOG( @"ERROR READING: %@", exception );
    }
    if( !loadedDict ) {
        loadedDict = [NSDictionary dictionary];
    }
    LOG( @"CACHE: HAS %i VALUES.", (int)[loadedDict count] );
    return loadedDict;
}

- (void) cacheSaveDirectoryIfValid:(NSDictionary*)dictToSave {
    LOG( @"CACHE: PLAUSIBILITY CHECK..." );
    NSUInteger numOfEntriesCached = _spacesDirectory ? [_spacesDirectory count] : 0;
    NSUInteger numOfEntriesToSave = dictToSave ? [dictToSave count] : 0;
    // A REFRESHED DIRECTORY OF HACKERSPACES SHOULD NOT VARY IN NUM OF ENTRIES
    // BY MORE THAN 20 PERCENT OF ALL ENTRIES LESS THAN THE CACHED VARIANT.
    // IF MORE THAN 20 PERCENT ARE MISSING SOMETHING LOOKS REALLY BADLY WRONG...
    CGFloat pausibleDifferenceInPercent = 0.2f;
    CGFloat numOfMinimumEntriesNeeded = numOfEntriesCached - (numOfEntriesCached * pausibleDifferenceInPercent);
    if( numOfEntriesToSave < numOfMinimumEntriesNeeded ) {
        LOG( @"CACHE: DATA TO CACHE LOOKS NOT PLAUSIBLE... ABORTING..." );
        return;
    }
    LOG( @"CACHE: LOOKS PLAUSIBLE... SAVING..." );
    // WE HAVE A PLAUSIBLE VALUE, SAVE IT
    [self cacheSaveDirectory:dictToSave];
}

- (void) cacheSaveDirectory:(NSDictionary*)dictToSave {
    NSString *pathToStore = [self cachePathDirectory];
    LOG( @"CACHE: SAVING... TO %@", pathToStore );
    BOOL wasSuccess = NO;
    @try {
        wasSuccess = [dictToSave writeToFile:pathToStore atomically:YES];
    }
    @catch( NSException *exception ) {
        wasSuccess = NO;
        LOG( @"ERROR WRITING: %@", exception );
    }
    if( !wasSuccess ) {
        LOG( @"ERROR WRITING STORAGE:\n%@", pathToStore );
    }
    LOG( @"CACHE: HAS %i VALUES.", (int)[dictToSave count] );
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

- (BOOL) hasValidSpaceDirectory {
    return ( _spacesDirectory && [_spacesDirectory count] > 0 );
}

#pragma mark - user actions

- (IBAction) actionShowAbout:(id)sender {
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    [[NSApplication sharedApplication] arrangeInFront:[NSApplication sharedApplication].windows];
}

- (IBAction) actionShowPreferencePanel:(id)sender {
    [self.preferenceController showWindow:self];
}

- (IBAction) actionSelectSpaceFromMenu:(NSMenuItem *)sender {
    self.latestStatus = SpaceStatusZero;
    self.latestSpaceStatusMessage = nil;
    self.statusItem.image = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.alternateImage = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.button.toolTip = LOC( @"Space: no message" );
    self.selectedSpaceMessage.title = LOC( @"Space: no message" );
    self.selectedSpaceMessage.hidden = YES;
    [self startPulseAnimationOnView:self.statusItem.button];
    [self selectSpace:sender.title];
}

- (IBAction) actionUpdateStatus:(id)sender {
    if( ![self hasValidSpaceDirectory] ) {
        [self fetchSpaceDirectory];
        return;
    }
    self.latestStatus = SpaceStatusZero;
    self.latestSpaceStatusMessage = nil;
    self.statusItem.image = [self imageForStatus:SpaceStatusUnknown];
    self.statusItem.alternateImage = [self imageForStatus:SpaceStatusUnknown];
    [self startPulseAnimationOnView:self.statusItem.button];
    [_selectedSpace fetchSpaceStatus];
}


@end
