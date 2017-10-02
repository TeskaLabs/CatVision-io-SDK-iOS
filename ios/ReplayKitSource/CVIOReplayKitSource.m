//
//  CVIOReplayKitSource.m
//  ios
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>
#include "CatVisionIO.h"
#include "CVIOReplayKitSource.h"

@implementation CVIOReplayKitSource {
	RPScreenRecorder * screenRecorder;
}

@synthesize delegate;

-(instancetype)init:(id<CVIOSourceDelegate>)in_delegate
{
	self = [super init];
	if (self == nil) return nil;
	
	delegate = in_delegate;
	screenRecorder = [RPScreenRecorder sharedRecorder];
	
	return self;
}

-(void)start
{
	[screenRecorder setMicrophoneEnabled:NO];

	if (![screenRecorder isAvailable])
	{
		//TODO: Signalise this better
		NSLog(@"Screen recorder is not available!");
		return;
	}
	
	[screenRecorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
		if (bufferType == RPSampleBufferTypeVideo) // We want video only now
		{
			[delegate handleSourceBuffer:sampleBuffer sampleType:bufferType];
		}
	} completionHandler:^(NSError * _Nullable error) {
		NSLog(@"!!! startCaptureWithHandler/completionHandler %@ !!!", error);
	}];
}

-(void)stop
{
	[screenRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
		NSLog(@"!!! stopCaptureWithHandler/completionHandler %@ !!!", error);
	}];
}

@end
