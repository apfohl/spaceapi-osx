//
//  Statuses.m
//  SpaceAPI
//
//  Created by Andreas Pfohl on 09.06.13.
//  Copyright (c) 2013 Andreas Pfohl. All rights reserved.
//

#import "Statuses.h"
#import "Spaces.h"

@interface Statuses ()

@property (nonatomic, strong) Spaces *spaces;

@end

@implementation Statuses

- (Spaces *)spaces {
  if(!_spaces) {
    _spaces = [[Spaces alloc] init];
  }
  return _spaces;
}

- (Boolean)isOpen:(NSString *)aSpace {
  NSDictionary *apiData = [self fetchSpaceData:aSpace];
  if (!apiData) {
    return NO;
  }

  NSNumber *openStatus;

  NSString *apiVersion = [apiData objectForKey:@"api"];
  if ([apiVersion isEqualToString:@"0.11"] || [apiVersion isEqualToString:@"0.12"]) {
    openStatus = [apiData objectForKey:@"open"];
  } else if ([apiVersion isEqualToString:@"0.13"]) {
    openStatus = [[apiData objectForKey:@"state"] objectForKey:@"open"];
  }

  return [openStatus boolValue];
}

- (NSArray *)getSpaceList {
  return [[[[self spaces] spaceList] allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSDictionary *)fetchSpaceData:(NSString *)aSpace {
  NSString *url = [[[self spaces] spaceList] valueForKey:aSpace];
  NSURL *spaceApiUrl = [NSURL URLWithString:url];
  NSData *apiResponse = [NSData dataWithContentsOfURL:spaceApiUrl];
  NSError *error = nil;

  NSDictionary *apiData = [NSJSONSerialization JSONObjectWithData:apiResponse options:NSJSONReadingMutableContainers error:&error];

  return (error ? nil : apiData);
}

@end
