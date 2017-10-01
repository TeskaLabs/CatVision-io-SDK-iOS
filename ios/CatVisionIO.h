//
//  ios.h
//  CatVision.io SDK for iOS
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SeaCatClient/SeaCatClient.h>
#import <VNCServer/VNCServer.h>

//! Project version number for ios.
FOUNDATION_EXPORT double CatVisionVersionNumber;

//! Project version string for ios.
FOUNDATION_EXPORT const unsigned char CatVisionVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ios/PublicHeader.h>

@interface CatVision : NSObject <SeaCatCSRDelegate, VNCServerDelegate>

+ (instancetype)sharedInstance;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)start;

@end

