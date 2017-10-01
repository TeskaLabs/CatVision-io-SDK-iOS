//
//  CVIOSeaCatPlugin.h
//  CatVisionIO
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <SeaCatClient/SeaCatClient.h>

@interface CVIOSeaCatPlugin : SeaCatPlugin

- (CVIOSeaCatPlugin *)init:(int)port;
- (void)configureSocket:(NSString *)socketAddress;
- (NSDictionary *)getCharacteristics;

@end

