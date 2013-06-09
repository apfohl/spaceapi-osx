//
//  Spaces.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 08.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "Spaces.h"

@implementation Spaces {
  NSDictionary *hackerspaces;
}

- (id)init {
  self = [super init];
  if (self) {
    [self fetchSpaces];
  }

  return self;
}

- (NSDictionary *)spaceList {
  return hackerspaces;
}

- (void)fetchSpaces {
  NSURL *spaceApiDirectoryUrl = [NSURL URLWithString:@"http://spaceapi.net/directory.json?api=0.12"];
  NSData *apiResponse = [NSData dataWithContentsOfURL:spaceApiDirectoryUrl];
  NSError *error = nil;

  hackerspaces = [NSJSONSerialization JSONObjectWithData:apiResponse options:NSJSONReadingMutableContainers error:&error];
}

- (void)updateSpaceList {
  [self fetchSpaces];
}

@end
