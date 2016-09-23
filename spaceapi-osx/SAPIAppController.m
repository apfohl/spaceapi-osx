//
//  SAPIAppController.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SAPIAppController.h"
#import "SAPIPreferenceController.h"
#import "SAPISpace.h"

@interface SAPIAppController ()

@property (nonatomic, strong) SAPIPreferenceController *preferenceController;
@property (nonatomic, strong) NSImage *imageBug;
@property (nonatomic, strong) NSImage *yellowLight;
@property (nonatomic, strong) NSImage *redLight;
@property (nonatomic, strong) NSImage *greenLight;

@end

@implementation SAPIAppController {
    NSOperationQueue *_workerQueue;
    NSDictionary *_spacesDirectory;
    SAPISpace *_selectedSpace;
    BOOL inDarkMode;
}

#pragma mark - destruction

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - construction

+ (void)initialize {
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
    }
    return self;
}

- (void) awakeFromNib { // NSStatusBarButton
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.wantsLayer = YES;
    self.statusItem.image = self.yellowLight;
    self.statusItem.alternateImage = self.yellowLight;
    self.statusItem.menu = self.mainMenu;
    self.statusItem.highlightMode = YES;
    inDarkMode = [[[NSAppearance currentAppearance] name] containsString:NSAppearanceNameVibrantDark];
}

#pragma mark - convenience

+ (id) dictionaryByReplacingNullsWithStringsInDictionary:(NSDictionary*)dictToClean {
    if( ![[dictToClean class] isSubclassOfClass:[NSDictionary class]] ) {
        if( [NSStringFromClass( [dictToClean class] ) isEqualToString:@"NSTaggedPointerString"] ) {
            NSString *taggedString = (NSString*)dictToClean;
            return [taggedString componentsSeparatedByString:@","];
        }
        else {
            NSLog( @"WARNING: EXPECTED DICTIONARY IS ACTUALLY INSTANCE OF: '%@'.", NSStringFromClass( [dictToClean class] ) );
            NSLog( @"WARNING: CONTENT IS:\n---\n%@\n---\n\n", dictToClean );
            return dictToClean;
        }
    }
    NSMutableDictionary *replaced = [NSMutableDictionary dictionaryWithDictionary:dictToClean];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    
    for( NSString *currentKey in dictToClean ) {
        id currentObject = [dictToClean objectForKey:currentKey];
        if( currentObject == nul ) {
            NSLog( @"WARNING: KEY '%@' WAS CONTAINING <null>-VALUE.", currentKey );
            NSLog( @"WARNING: BELONGED TO DICTIONARY '%@'.", dictToClean );
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

- (SAPIPreferenceController *)preferenceController {
    if (!_preferenceController) {
        _preferenceController = [[SAPIPreferenceController alloc] init];
    }
    return _preferenceController;
}

- (NSImage*) imageBug {
    if( !_imageBug ) {
        if( inDarkMode ) {
            _imageBug = [NSImage imageNamed:@"bug"];
        }
        else {
            _imageBug = [NSImage imageNamed:@"bug"];
        }
    }
    return _imageBug;
}

- (NSImage*) yellowLight {
    if( !_yellowLight ) {
        if( inDarkMode ) {
            _yellowLight = [NSImage imageNamed:@"unknown_dark"];
        }
        else {
            _yellowLight = [NSImage imageNamed:@"unknown"];
        }
    }
    return _yellowLight;
}

- (NSImage*) redLight {
    if( !_redLight ) {
        if( inDarkMode ) {
            _redLight = [NSImage imageNamed:@"closed_dark"];
        } else {
            _redLight = [NSImage imageNamed:@"closed"];
        }
    }
    return _redLight;
}

- (NSImage*) greenLight {
    if( !_greenLight ) {
        if( inDarkMode ) {
            _greenLight = [NSImage imageNamed:@"open_dark"];
        } else {
            _greenLight = [NSImage imageNamed:@"open"];
        }
    }
    return _greenLight;
}

- (void) selectSpace:(NSString *)name {
    if( _selectedSpace ) {
        [_selectedSpace timerCancel];
    }
    SAPISpace *space = [[SAPISpace alloc] initWithName:name andAPIURL:[_spacesDirectory objectForKey:name]];
    [space fetchSpaceStatus];
    _selectedSpace = space;

    self.selectedSpaceItem.title = [NSString stringWithFormat:@"Space: %@", space.name];

    [SAPIPreferenceController setSelectedSpace:space.name];
}

#pragma mark - notifications

- (void) handleInvalidJsonError:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = [notification userInfo];
        [self stopPulseAnimationOnView:self.statusItem.button];
        self.statusItem.image = self.imageBug;
        self.statusItem.alternateImage = self.imageBug;
        self.selectedSpaceMessage.title = [NSString stringWithFormat:@"ERROR:\n%@", [userInfo objectForKey:@"error"]];
        self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
        self.selectedSpaceMessage.hidden = NO;
        NSLog( @"\n*** FATAL-API-FAIL ***\n\n  API: %@\n  URL: %@\nERROR: %@\n JSON: %@\n", [userInfo objectForKey:@"apicall"],[userInfo objectForKey:@"url"], [userInfo objectForKey:@"error"], [userInfo objectForKey:@"json"]);
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
                self.statusItem.image = [[[notification userInfo] objectForKey:@"openStatus"] boolValue] ? self.greenLight : self.redLight;
                self.statusItem.alternateImage = [[[notification userInfo] objectForKey:@"openStatus"] boolValue] ? self.greenLight : self.redLight;
                NSString *statusMessage = [[notification userInfo] objectForKey:@"statusMessage"];
                self.selectedSpaceMessage.title = statusMessage ?: @"Space: no message";
                self.statusItem.button.toolTip = self.selectedSpaceMessage.title;
                self.selectedSpaceMessage.hidden = ( statusMessage == nil );
        }
        @catch (NSException *exception) {
            NSLog( @"handleOpenStatusChange Error: %@\n\n---\n%@", [notification userInfo], exception );
            self.statusItem.image = self.imageBug;
            self.statusItem.alternateImage = self.imageBug;
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
                    _spacesDirectory = [SAPIAppController dictionaryByReplacingNullsWithStringsInDictionary:_spacesDirectory];
                    NSString *spaceName = [SAPIPreferenceController selectedSpace];
                    if( spaceName ) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                            [self selectSpace:spaceName];
                        }];
                    }
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                        [self.spacesMenu removeItemAtIndex:0];
                    }];
                    
                    for (NSString *name in [[_spacesDirectory allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
                        NSMenuItem *spaceItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(actionSelectSpaceFromMenu:) keyEquivalent:@""];
                        spaceItem.target = self;
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                            [self.spacesMenu addItem:spaceItem];
                        }];
                    }
                }
                @catch (NSException *exception) {
                    NSLog( @"fetchSpaceDirectory Error decoding JSON: %@\n\n---\n%@", _spacesDirectory, exception );
                    self.statusItem.image = self.imageBug;
                    self.statusItem.alternateImage = self.imageBug;
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
    self.statusItem.image = self.yellowLight;
    self.statusItem.alternateImage = self.yellowLight;
    self.statusItem.button.toolTip = @"Space: no message";
    self.selectedSpaceMessage.title = @"Space: no message";
    self.selectedSpaceMessage.hidden = YES;
    [self startPulseAnimationOnView:self.statusItem.button];
    [self selectSpace:sender.title];
}

- (IBAction) actionUpdateStatus:(NSMenuItem *)sender {
    self.statusItem.image = self.yellowLight;
    self.statusItem.alternateImage = self.yellowLight;
    [self startPulseAnimationOnView:self.statusItem.button];
    [_selectedSpace fetchSpaceStatus];
}


@end
