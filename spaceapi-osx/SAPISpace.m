//
//  SAPISpace.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 29.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "PreferenceController.h"
#import "AppController.h"
#import "SAPISpace.h"
#import "SAPILocation.h"
#import "SAPISpaceFed.h"

NSString * const SAPIOpenStatusChangedNotification      = @"SAPIOpenStatusChanged";
NSString * const SAPIStatusUpdateFailedNotification     = @"SAPIStatusUpdateFailed";
NSString * const SAPIHasInvalidJsonNotification         = @"SAPIHasInvalidJsonNotification";

@implementation SAPISpace {
    NSDictionary *_spaceDictionary;
    NSOperationQueue *_workerQueue;
    NSTimer *_fetchTimer;
}

#pragma mark - construction

- (id) initWithName:(NSString *)name andAPIURL:(NSString *)apiURL {
    self = [super init];
    if (self) {
        _workerQueue = [[NSOperationQueue alloc] init];
        self.name = name;
        self.apiURL = apiURL;
        [self setOpen:NO];
        [self timerStart];
    }
    return self;
}

#pragma mark - timer management

- (void) timerStart {
    if( _fetchTimer && [_fetchTimer isValid] ) {
        [_fetchTimer invalidate];
    }
    _fetchTimer = [NSTimer scheduledTimerWithTimeInterval:[PreferenceController updateInterval] target:self selector:@selector(timerFetchData:) userInfo:nil repeats:NO];
}

- (void) timerCancel {
    if( _fetchTimer && [_fetchTimer isValid] ) {
        [_fetchTimer invalidate];
    }
    _fetchTimer = nil;
}

- (void) timerFetchData:(NSTimer *)aTimer {
    [self fetchSpaceStatus];
}

#pragma mark - json fetching

- (NSDictionary*) jsonMapping {
    return @{@"api":@"NSString",
             @"space":@"NSString",
             @"logo":@"NSString",
             @"url":@"NSString",
             @"location":@"SAPILocation",
             @"spacefed":@"SAPISpaceFed",
             @"cams":@"NSArray",
             @"stream":@"SAPIStream",
             @"state":@"SAPIState",
             @"events":@"NSArray",
             @"contact":@"SAPIContact",
             @"issue_report_channels":@"NSArray",
             @"sensors":@"SAPISensors",
             @"feeds":@"SAPIFeeds",
             @"cache":@"SAPICache",
             @"projects":@"NSArray",
             @"radio_show":@"NSArray"};
}

- (void) fetchSpaceStatus {
    [self timerStart];
    NSURL *spaceAPIUrl = [NSURL URLWithString:self.apiURL];
    NSURLRequest *spaceAPIRequest = [[NSURLRequest alloc] initWithURL:spaceAPIUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [NSURLConnection sendAsynchronousRequest:spaceAPIRequest queue:_workerQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data && !error) {
            NSError *jsonError;
            NSString *jsonRawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            _spaceDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            // SANITIZE DATA...
            LOG( @"%@: JSON DICTIONARY IS...\n---\n%@\n---\n\n", NSStringFromClass([self class]), _spaceDictionary );
            _spaceDictionary = [AppController dictionaryByReplacingNullsWithStringsInDictionary:_spaceDictionary];
            @try {
                if( !jsonError ) {
                    BOOL useModernParsing = NO;
                    
                    if( useModernParsing ) {
                        [self jsonTakeValuesFromDictionary:_spaceDictionary forApiVersion:[_spaceDictionary objectForKey:@"api"]];
                    }
                    else {
                        NSNumber *openStatus;
                        NSString *statusMessage;
                        NSString *version = [_spaceDictionary objectForKey:@"api"];
                        
                        if (version) {
                            if ([version isEqualToString:@"0.11"] || [version isEqualToString:@"0.12"]) {
                                openStatus = [_spaceDictionary objectForKey:@"open"];
                                statusMessage = [_spaceDictionary objectForKey:@"status"];
                            }
                            else {
                                openStatus = [[_spaceDictionary objectForKey:@"state"] objectForKey:@"open"];
                                statusMessage = [[_spaceDictionary objectForKey:@"state"] objectForKey:@"message"];
                            }
                            
                            NSDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:openStatus forKey:@"openStatus"];
                            if (statusMessage) {
                                [userInfo setValue:statusMessage forKey:@"statusMessage"];
                            }
                            [[NSNotificationCenter defaultCenter] postNotificationName:SAPIOpenStatusChangedNotification object:self userInfo:userInfo];
                            
                            [self setOpen:[openStatus boolValue]];
                        }
                    }
                }
                else {
                    if( !jsonRawString ) {
                        jsonRawString = @"[NIL]";
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:SAPIHasInvalidJsonNotification object:self userInfo:@{@"error":jsonError, @"json":jsonRawString,@"apicall":@"spacestatus",@"url":[spaceAPIUrl absoluteString]}];
                }
            }
            @catch (NSException *exception) {
                LOG( @"_spaceDictionary decoding Error: %@\n\n---\n%@", _spaceDictionary, exception );
                [[NSNotificationCenter defaultCenter] postNotificationName:SAPIStatusUpdateFailedNotification object:self userInfo:nil];
            }
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:SAPIStatusUpdateFailedNotification object:self userInfo:nil];
        }
    }];
}

@end
