//
//  SAPIGenericApiObject.m
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

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
#import "SAPIIcon.h"

@implementation SAPIGenericApiObject

#pragma mark - api convenience

- (CGFloat)apiVersionFloatFromString:(NSString*)apiVersion {
    CGFloat version = 0.0f;
    @try {
        version = [apiVersion floatValue];
    }
    @catch (NSException *exception) {
        LOG( @"ERROR PARSING API VERSION FLOAT VALUE FROM STRING: %@", apiVersion );
    }
    return version;
}

- (NSString*)apiVersionStringFromFloat:(CGFloat)version {
    return [NSString stringWithFormat:@"%0.2f", version];
}

- (CGFloat) apiVersionMostRecent {
    CGFloat version = 0.13f;
    return version;
}

- (BOOL) isMostRecentApiVersion:(CGFloat)apiVersion {
    return apiVersion == [self apiVersionMostRecent];
}

- (BOOL) hasDictionaryMostRecentApi:(NSDictionary*)dict {
    NSString *apiVersion = [dict objectForKey:@"api"];
    return [self isMostRecentApiVersion:[self apiVersionFloatFromString:apiVersion]];
}

#pragma mark - api compatibility converter

/*
{
    RESULT =     {
        ST2 = 1474813563666;
        ST3 = OPEN;
        ST5 = "Linux User Group Bremen Stammtisch - siehe http://www.lug-bremen.info/!";
    };
    SUCCESS = "Status found";
    address = "Bornstra\U00dfe 14/15, 28195 Bremen, Germany";
    api = "0.12";
    contact =     {
        email = "info@hackerspace-bremen.de";
        phone = "+49 421 14 62 92 15";
        twitter = "@hspacehb";
    };
    icon =     {
        closed = "http://hackerspacehb.appspot.com/images/status_zu_48px.png";
        open = "http://hackerspacehb.appspot.com/images/status_auf_48px.png";
    };
    lastchange = 1474813563;
    lat = "53.08177947998047";
    logo = "http://hackerspacehb.appspot.com/images/hackerspace_icon.png";
    lon = "8.805830955505371";
    open = 1;
    space = "Hackerspace Bremen e.V.";
    status = "Linux User Group Bremen Stammtisch - siehe http://www.lug-bremen.info/!";
    url = "http://www.hackerspace-bremen.de";
}
*/

/*
{
    api = "0.13";
    contact =     {
        email = "hackerspace-vs@lieber-anders.de";
        phone = "+49 221 596196638";
        twitter = "@vspace.one";
    };
    "issue_report_channels" =     (
                                   twitter,
                                   email
                                   );
    location =     {
        address = "Wilhelm-Binder-Str. 19, 78048 VS-Villingen, Germany";
        lat = "48.065003";
        lon = "8.456495";
    };
    logo = "https://wiki.vspace.one/lib/exe/fetch.php?cache=&media=verein:logo_vspaceone.png";
    sensors =     {
        humidity =         (
                            {
                                location = Maschinenraum;
                                unit = "%";
                                value = "39.1";
                            },
                            {
                                location = "Br\U00fccke";
                                unit = "%";
                                value = "41.9";
                            }
                            );
        temperature =         (
                               {
                                   location = Maschinenraum;
                                   unit = "\U00b0C";
                                   value = "24.5";
                               },
                               {
                                   location = "Br\U00fccke";
                                   unit = "\U00b0C";
                                   value = "23.4";
                               }
                               );
    };
    space = "vspace.one";
    state =     {
        open = 0;
    };
    url = "https://vspace.one";
}
*/

- (NSDictionary*) upgradeJsonDictionary:(NSDictionary*)inputDictionary {
    NSMutableDictionary *currentDictionary = [NSMutableDictionary dictionaryWithDictionary:inputDictionary];
    NSMutableDictionary *targetDictionary = [NSMutableDictionary dictionary];
    NSString *apiVersion = [currentDictionary objectForKey:@"api"];
    CGFloat currentApi = [self apiVersionFloatFromString:apiVersion];
    // LEGACY SUPPORT FOR OLD APIS
    if( currentApi == 0.11 ) {
        [targetDictionary setObject:@"0.13" forKey:@"api"];
    }
    if( currentApi == 0.12 ) {
        [targetDictionary setObject:@"0.13" forKey:@"api"];
        
        
    }
    return [NSDictionary dictionaryWithDictionary:targetDictionary];
}

#pragma mark - api property mapping (for subclasses)

- (NSDictionary*) jsonMapping {
    // NEEDS TO BE IMPLEMENTED IN SUBCLASS
    LOG( @"CLASS: %@ NEEDS TO IMPLEMENT jsonMapping-METHOD!", NSStringFromClass([self class]) );
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void) jsonTakeValuesFromDictionary:(NSDictionary*)dict forApiVersion:(NSString*)apiVersion {
    LOG( @"%@: JSON DICTIONARY IS...\n---\n%@\n---\n\n", NSStringFromClass([self class]), dict );
    // FIX JSON VIA UPGRADE TRANSFORM
    if( ![self hasDictionaryMostRecentApi:dict] ) {
        dict = [self upgradeJsonDictionary:dict];
    }
    
    NSArray *keysToMap = [[self jsonMapping] allKeys];
    
    for( NSString* currentKey in keysToMap ) {
        @try {
            id value = [dict objectForKey:currentKey];
            if( [value isKindOfClass:[NSNull class]] || ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"<null>"] ) ) {
                // DO NOT TRY TO MAP THIS VALUE
            }
            else {
                // FIND OUT CLASS
                NSString *mappingClassName  = [[self jsonMapping] objectForKey:currentKey];
                id objectToMap = [[NSClassFromString( mappingClassName ) alloc] init];
                if( [value isKindOfClass:NSClassFromString( mappingClassName )] ) {
                    [self setValue:value forKey:currentKey];
                }
                else {
                    if( [value isKindOfClass:[NSDictionary class]] ) {
                        [self setValue:objectToMap forKey:currentKey];
                        [objectToMap jsonTakeValuesFromDictionary:value forApiVersion:apiVersion];
                    }
                    else {
                        LOG( @"%@: UNABLE TO MAP: %@ FOR KEY: %@", NSStringFromClass([self class]), NSStringFromClass( [value class] ), currentKey );
                    }
                }
            }
        }
        @catch (NSException *exception) {
            LOG( @"JSON MAPPING ERROR: takeValuesFromJsonDictionary failed with key '%@'", currentKey );
            LOG( @"JSON MAPPING ERROR: takeValuesFromJsonDictionary failed with exception %@", exception );
        }
    }
}

@end
