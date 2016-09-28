//
//  SAPILocation.h
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPIGenericApiObject.h"

@interface SAPILocation : SAPIGenericApiObject

@property (strong) NSString *address;  // The postal address of your space, e.g. Netzladen e.V., Breite Straße 74, 53111 Bonn, Germany
@property (strong) NSNumber *lat;      // Latitude of your space location, in degree with decimal places (WGS84)
@property (strong) NSNumber *lon;      // Longitude of your space location, in degree with decimal places. (WGS84)

@end
