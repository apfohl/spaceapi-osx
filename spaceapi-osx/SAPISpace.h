//
//  SAPISpace.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 29.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPIGenericApiObject.h"

#import "SAPILocation.h"
#import "SAPISpaceFed.h"
#import "SAPIStream.h"
#import "SAPIState.h"
#import "SAPIEvent.h"
#import "SAPIContact.h"
#import "SAPISensors.h"
#import "SAPIFeeds.h"
#import "SAPICache.h"
#import "SAPIRadioShow.h"

extern NSString * const SAPIOpenStatusChangedNotification;
extern NSString * const SAPIStatusUpdateFailedNotification;
extern NSString * const SAPIHasInvalidJsonNotification;

@interface SAPISpace : SAPIGenericApiObject

@property (strong) NSString *name;
@property (strong) NSString *apiURL;

// properties from JSON, see http://spaceapi.net/documentation
@property (strong) NSString *api;                   // The version of SpaceAPI your endpoint uses
@property (strong) NSString *space;                 // The name of your space
@property (strong) NSString *logo;                  // URL to your space logo
@property (strong) NSString *url;                   // URL to your space website
@property (strong) SAPILocation *location;          // Position data such as a postal address or geographic coordinates
@property (strong) SAPISpaceFed *spacefed;          // A flag indicating if the hackerspace uses SpaceFED
@property (strong) NSArray *cams;                   // URL(s) of webcams in your space
@property (strong) SAPIStream *stream;              // A mapping of stream types to stream URLs
@property (strong) SAPIState *state;                // A collection of status-related data
@property (strong) NSArray *events;                 // Events which happened recently in your space and which could be interesting to the public
@property (strong) SAPIContact *contact;            // Contact information about your space
@property (strong) NSArray *issue_report_channels;  // all communication channels where you want to get automated issue reports about your SpaceAPI
@property (strong) SAPISensors *sensors;            // Data of various sensors in your space
@property (strong) SAPIFeeds *feeds;                // Feeds where users can get updates of your space, blog, wiki
@property (strong) SAPICache *cache;                // Specifies options about caching of your SpaceAPI endpoint
@property (strong) NSArray *projects;               // Your project sites (links to GitHub, wikis or wherever your projects are hosted)
@property (strong) NSArray *radio_show;             // list of radio shows that your hackerspace might broadcast


@property (nonatomic, assign, getter = isOpen) BOOL open;

- (id) initWithName:(NSString *)name andAPIURL:(NSString *)apiURL;
- (void) fetchSpaceStatus;
- (void) timerStart;
- (void) timerCancel;

@end
