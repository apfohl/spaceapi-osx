//
//  SAPIGenericApiObject.h
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SAPIGenericApiObject : NSObject

- (NSDictionary*) jsonMapping;
- (void) jsonTakeValuesFromDictionary:(NSDictionary*)dict forApiVersion:(NSString*)apiVersion;

@end
