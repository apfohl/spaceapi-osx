//
//  SAPIState.h
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPIGenericApiObject.h"

#import "SAPIIcon.h"

@interface SAPIState : SAPIGenericApiObject

@property (strong) NSArray *open;
@property (strong) NSNumber *lastchange;
@property (strong) NSString *trigger_person;
@property (strong) NSString *message;
@property (strong) SAPIIcon *icon;

@end
