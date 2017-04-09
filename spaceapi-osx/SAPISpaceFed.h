//
//  SAPISpaceFed.h
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPIGenericApiObject.h"

@interface SAPISpaceFed : SAPIGenericApiObject

@property (strong) NSNumber *spacenet;       // Position data such as a postal address or geographic coordinates
@property (strong) NSNumber *spacesaml;
@property (strong) NSNumber *spacephone;

@end
