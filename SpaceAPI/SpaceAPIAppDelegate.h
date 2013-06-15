//
//  SpaceAPIAppDelegate.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 14.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpaceAPIController.h"

@interface SpaceAPIAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet SpaceAPIController *controller;

@end
