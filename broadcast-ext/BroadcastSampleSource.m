//
//  BroadcastSampleSource.m
//  broadcast-ext
//
//  Created by Ales Teska on 8.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BroadcastSampleSource.h"

@implementation BroadcastSampleSource

@synthesize delegate;

-(instancetype)init:(id<CVIOSourceDelegate>)in_delegate
{
	self = [super init];
	if (self == nil) return nil;
	
	delegate = in_delegate;
	
	return self;
}

- (CGSize)getSize
{
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGFloat screenScale = [[UIScreen mainScreen] scale]; // Adjust screen size by subpixel scale
	CGSize ret = {
		.width = screenBounds.size.width * screenScale,
		.height = screenBounds.size.height * screenScale,
	};
	return ret;
}

-(void)start
{
}

-(void)stop
{
}

@end
