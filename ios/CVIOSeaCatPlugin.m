//
//  CVIOSeaCatPlugin.m
//  ios
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#import "CVIOSeaCatPlugin.h"

@implementation CVIOSeaCatPlugin {
	int myPort;
}

- (CVIOSeaCatPlugin *)init:(int)port
{
	self = [super init];
	if (self == nil) return nil;
	myPort = port;

	return self;
}

- (NSDictionary *)getCharacteristics
{
	return @{ @"RA" : [NSString stringWithFormat:@"vnc:%d", myPort] };
}

- (void)configureSocket:(NSString *) socketAddress
{
	[SeaCatClient configureSocket:myPort domain:AF_UNIX sock_type:SOCK_STREAM protocol:0 peerAddress:socketAddress peerPort:@""];
}

@end
