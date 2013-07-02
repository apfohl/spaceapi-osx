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
@property (nonatomic, strong) NSImage *yellowLight;
@property (nonatomic, strong) NSImage *redLight;
@property (nonatomic, strong) NSImage *greenLight;

@end

@implementation SAPIAppController {
    NSOperationQueue *_workerQueue;
    NSDictionary *_spacesDirectory;
    SAPISpace *_selectedSpace;
}

+ (void)initialize {
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    [defaultValues setObject:[NSNumber numberWithLong:300] forKey:SAPIUpdateIntervalKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (id)init
{
    self = [super init];
    if (self) {
        _workerQueue = [[NSOperationQueue alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenStatusChange:) name:SAPIOpenStatusChangedNotification object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (SAPIPreferenceController *)preferenceController
{
    if (!_preferenceController) {
        _preferenceController = [[SAPIPreferenceController alloc] init];
    }
    return _preferenceController;
}

- (NSImage *)yellowLight
{
    if (!_yellowLight) {
        _yellowLight = [NSImage imageNamed:@"yellow"];
    }
    return _yellowLight;
}

- (NSImage *)redLight
{
    if (!_redLight) {
        _redLight = [NSImage imageNamed:@"red"];
    }
    return _redLight;
}

- (NSImage *)greenLight
{
    if (!_greenLight) {
        _greenLight = [NSImage imageNamed:@"green"];
    }
    return _greenLight;
}

- (void)awakeFromNib
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.image = self.yellowLight;
    self.statusItem.menu = self.mainMenu;
    self.statusItem.highlightMode = YES;
}

- (IBAction)showPreferencePanel:(id)sender
{    
    [self.preferenceController showWindow:self];
}

- (void)selectSpace:(NSString *)name
{
    SAPISpace *space = [[SAPISpace alloc] initWithName:name andAPIURL:[_spacesDirectory objectForKey:name]];
    [space fetchSpaceData];
    _selectedSpace = space;

    self.selectedSpaceItem.title = [NSString stringWithFormat:@"Space: %@", space.name];

    [SAPIPreferenceController setSelectedSpace:space.name];
}

- (IBAction)selectSpaceFromMenu:(NSMenuItem *)sender
{
    [self selectSpace:sender.title];
}

- (IBAction)clickUpdateStatus:(NSMenuItem *)sender
{
    self.statusItem.image = self.yellowLight;
    [_selectedSpace fetchSpaceData];
}

- (void)handleOpenStatusChange:(NSNotification *)notification
{
    self.statusItem.image = [[[notification userInfo] objectForKey:@"openStatus"] boolValue] ? self.greenLight : self.redLight;
}

- (void)fetchSpaceDirectory
{
    NSURL *spaceAPIDirectoryUrl = [NSURL URLWithString:@"http://spaceapi.net/directory.json"];
    NSURLRequest *spaceAPIDirectoryRequest = [[NSURLRequest alloc] initWithURL:spaceAPIDirectoryUrl];
    [NSURLConnection sendAsynchronousRequest:spaceAPIDirectoryRequest queue:_workerQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data && !error) {
            _spacesDirectory = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

            NSString *spaceName = [SAPIPreferenceController selectedSpace];
            if (spaceName) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                    [self selectSpace:spaceName];
                }];
            }

            [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                [self.spacesMenu removeItemAtIndex:0];
            }];

            for (NSString *name in [[_spacesDirectory allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
                NSMenuItem *spaceItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(selectSpaceFromMenu:) keyEquivalent:@""];
                spaceItem.target = self;

                [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                    [self.spacesMenu addItem:spaceItem];
                }];
            }
        }
    }];
}

@end
