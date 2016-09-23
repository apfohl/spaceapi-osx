//
//  SAPISpace.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 29.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "SAPISpace.h"
#import "SAPIPreferenceController.h"
#import "SAPIAppController.h"

NSString * const SAPIOpenStatusChangedNotification = @"SAPIOpenStatusChanged";
NSString * const SAPIStatusUpdateFailedNotification = @"SAPIStatusUpdateFailed";
NSString * const SAPIHasInvalidJsonNotification = @"SAPIHasInvalidJsonNotification";

@implementation SAPISpace {
    NSDictionary *_spaceData;
    NSOperationQueue *_workerQueue;
    NSTimer *_fetchTimer;
}

- (id) initWithName:(NSString *)name andAPIURL:(NSString *)apiURL {
    self = [super init];
    if (self) {
        _workerQueue = [[NSOperationQueue alloc] init];
        self.name = name;
        self.apiURL = apiURL;
        [self setOpen:NO];

        _fetchTimer = [NSTimer scheduledTimerWithTimeInterval:[SAPIPreferenceController updateInterval] target:self selector:@selector(timerFetchData:) userInfo:nil repeats:NO];
    }

    return self;
}

- (void) timerCancel {
    [_fetchTimer invalidate];
    _fetchTimer = nil;
}

- (void) timerFetchData:(NSTimer *)aTimer {
    [self fetchSpaceStatus];
    _fetchTimer = [NSTimer scheduledTimerWithTimeInterval:[SAPIPreferenceController updateInterval] target:self selector:@selector(timerFetchData:) userInfo:nil repeats:NO];
}

- (void) fetchSpaceStatus {
    NSURL *spaceAPIUrl = [NSURL URLWithString:self.apiURL];
    NSURLRequest *spaceAPIRequest = [[NSURLRequest alloc] initWithURL:spaceAPIUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [NSURLConnection sendAsynchronousRequest:spaceAPIRequest queue:_workerQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data && !error) {
            NSError *jsonError;
            NSString *jsonRawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            _spaceData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            // SANITIZE DATA...
            _spaceData = [SAPIAppController dictionaryByReplacingNullsWithStringsInDictionary:_spaceData];
            @try {
                if( !jsonError ) {
                    NSNumber *openStatus;
                    NSString *statusMessage;
                    NSString *version = [_spaceData objectForKey:@"api"];
                    
                    if (version) {
                        if ([version isEqualToString:@"0.11"] || [version isEqualToString:@"0.12"]) {
                            openStatus = [_spaceData objectForKey:@"open"];
                            statusMessage = [_spaceData objectForKey:@"status"];
                        } else {
                            openStatus = [[_spaceData objectForKey:@"state"] objectForKey:@"open"];
                            statusMessage = [[_spaceData objectForKey:@"state"] objectForKey:@"message"];
                        }
                        
                        NSDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:openStatus forKey:@"openStatus"];
                        if (statusMessage) {
                            [userInfo setValue:statusMessage forKey:@"statusMessage"];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:SAPIOpenStatusChangedNotification object:self userInfo:userInfo];
                        
                        [self setOpen:[openStatus boolValue]];
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
                NSLog( @"_spaceData decoding Error: %@\n\n---\n%@", _spaceData, exception );
                [[NSNotificationCenter defaultCenter] postNotificationName:SAPIStatusUpdateFailedNotification object:self userInfo:nil];
            }
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:SAPIStatusUpdateFailedNotification object:self userInfo:nil];
        }
    }];
}

@end
