//
//  SAPIPreferenceController.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 28.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SAPIPreferenceController.h"

NSString * const SAPIUpdateIntervalKey = @"SAPIUpdateInterval";
NSString * const SAPISelectedSpaceKey = @"SAPIUpdateSelectedSpace";

@implementation SAPIPreferenceController

+ (long) updateInterval {
    return [[NSUserDefaults standardUserDefaults] integerForKey:SAPIUpdateIntervalKey];
}

+ (void) setUpdateInterval:(long)interval {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:interval] forKey:SAPIUpdateIntervalKey];
}

+ (NSString*) selectedSpace {
    return [[NSUserDefaults standardUserDefaults] stringForKey:SAPISelectedSpaceKey];
}

+ (void) setSelectedSpace:(NSString *)spaceName {
    [[NSUserDefaults standardUserDefaults] setObject:spaceName forKey:SAPISelectedSpaceKey];
}

- (id) init {
    self = [super initWithWindowNibName:@"Preferences"];
    return self;
}

- (IBAction) actionChangeUpdateInterval:(NSTextField *)sender {
    [SAPIPreferenceController setUpdateInterval:[self.intervalField integerValue]];
}

- (void) windowDidLoad {
    [super windowDidLoad];
    [self.intervalField setStringValue:[NSString stringWithFormat:@"%li", [SAPIPreferenceController updateInterval]]];
}

@end
