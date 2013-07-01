//
//  SAPISpace.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 29.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const SAPIOpenStatusChangedNotification;

@interface SAPISpace : NSObject

@property (strong) NSString *name;
@property (strong) NSString *apiURL;
@property (nonatomic, assign, getter = isOpen) BOOL open;

- (id)initWithName:(NSString *)name andAPIURL:(NSString *)apiURL;
- (void)fetchSpaceData;

@end
