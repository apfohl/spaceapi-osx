//
//  SAPIStream.h
//  spaceapi-osx
//
//  Created by Lincoln Six Echo on 25.09.16.
//  Copyright © 2016 Andreas Pfohl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPIGenericApiObject.h"

@interface SAPIStream : SAPIGenericApiObject

@property (strong) NSString *m4;         // A mapping of stream types to stream URLs, Your mpg stream URL, e.g. http//example.org/stream.mpg
@property (strong) NSString *mjpeg;      // e.g. http://example.org/stream.mjpeg
@property (strong) NSString *ustream;    // e.g. http://www.ustream.tv/channel/hackspsps

@end
