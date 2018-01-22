//
//  VNCServer.h
//  VNCServer
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for VNCServer.
FOUNDATION_EXPORT double VNCServerVersionNumber;

//! Project version string for VNCServer.
FOUNDATION_EXPORT const unsigned char VNCServerVersionString[];

@interface VNCServer : NSObject


- (id)init:(int(^)(void))takeImage address:(NSString *)socketAddress size:(CGSize)size downScaleFactor:(int)factor;
- (void)start;
- (void)stop;
- (BOOL)isStarted;

- (BOOL)isSizeDifferent:(CGSize)size;

- (void)imageReady;

- (void)pushPixels_RGBA8888:(const unsigned char *)buffer length:(ssize_t)length row_stride:(int)s_stride;
- (void)pushPixels_420YpCbCr8BiPlanarFullRange:(CVImageBufferRef)image;

@end
