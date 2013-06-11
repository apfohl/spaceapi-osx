//
//  Statuses.h
//  SpaceAPI
//
//  Created by Andreas Pfohl on 09.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Statuses : NSObject

- (Boolean)isOpen:(NSString *)aSpace;
- (NSArray *)getSpaceList;

@end
