//
//  CatVision.m
//  CatVision.io SDK for iOS
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SeaCatClient/SeaCatClient.h>

#import "CVIOSeaCatPlugin.h"
#import "CVIOSeaCatCSR.h"
#import "CatVisionIO.h"
#import "VNCServer.h"
#import "ReplayKitSource/CVIOReplayKitSource.h"

@implementation CatVision {
	NSString * socketAddress;
	VNCServer * mVNCServer;
	BOOL mStarted;
	CVIOSeaCatPlugin * plugin;
	CVIOSeaCatCSR * CSR;
	id<CVIOSource> source;
	NSTimer * timer;

	NSLock* capturedImageLock;
	CVImageBufferRef capturedImage;
}

+ (instancetype)sharedInstance
{
	static CatVision *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[CatVision alloc] initPrivate];
	});
	return sharedInstance;
}

- (instancetype)initPrivate
{
	self = [super init];
	if (self == nil) return nil;

	mVNCServer = nil;
	mStarted = NO;

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSMutableString *addr = [[paths objectAtIndex:0] mutableCopy];
	
	NSError *error;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:addr withIntermediateDirectories:YES attributes:nil error:&error])
	{
		NSLog(@"Create directory error: %@", error);
	}

	[addr appendString:@"/vnc.s"]; //TODO: socket name can be more unique - it will allow to start more than one VNC server if needed
	socketAddress = [addr copy];
	
	[SeaCatClient setApplicationId:@"com.teskalabs.cvio"];
	//This is to enable SeaCat debug logging [SeaCatClient setLogMask:SC_LOG_FLAG_DEBUG_GENERIC];
	plugin = [[CVIOSeaCatPlugin alloc] init:5900];
	
	CSR = [[CVIOSeaCatCSR alloc] init];
	
	source = nil;
	timer = nil;
	capturedImage = nil;
	capturedImageLock = [[NSLock alloc] init];
	
	[SeaCatClient configureWithCSRDelegate:CSR];
	[plugin configureSocket:socketAddress];

	return self;
}

- (void)setSource:(id<CVIOSource>)in_source
{
	if (mStarted != NO)
	{
		NSLog(@"CVIO Source can be changed only if CatVision.io is not started");
		return;
	}

	source = in_source;
}

- (BOOL)start
{
	mStarted = YES;

	// ReplayKit is a default source
	if (source == nil)
	{
		source = [[CVIOReplayKitSource alloc] init:self];
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		[source start];
	});
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// Wait till SeaCat is ready
		//TODO: This can be implemented in much more 'Grand Central Dispatch friendly' way, avoid sleep(1)
		while (![SeaCatClient isReady])
		{
			NSLog(@"SeaCat is not ready (%@) ... waiting", [SeaCatClient getState]);
			sleep(1);
		}
		NSLog(@"SeaCat is READY");
		[SeaCatClient connect];
	});

	if (self->timer != nil)
	{
		[self->timer invalidate];
		self->timer = nil;
	}
	self->timer = [NSTimer scheduledTimerWithTimeInterval: 2.0
												  target: self
												selector:@selector(onTick:)
												userInfo: nil
												  repeats:YES
	];
	
	return YES;
}

-(void)onTick:(NSTimer *)timer
{
	if (mVNCServer != nil)
	{
		[mVNCServer tick];
	}
}

- (BOOL)stop
{
	if (mVNCServer != nil)
	{
		[mVNCServer stop];
		mVNCServer = nil;
	}

	if (source != nil)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[source stop];
			source = nil;
		});
	}
	
	mStarted = NO;

	[self->timer invalidate];
	self->timer = nil;

	return YES;
}

-(void)handleSourceBuffer:(CMSampleBufferRef)sampleBuffer sampleType:(RPSampleBufferType)sampleType
{
	CVImageBufferRef c = CMSampleBufferGetImageBuffer(sampleBuffer);
	if (c == NULL)
	{
		NSLog(@"CVIO CMSampleBufferGetImageBuffer() failed");
		return;
	}

	[capturedImageLock lock];
	@try
	{
		if (capturedImage != nil)
		{
			CVPixelBufferRelease(capturedImage);
			capturedImage = nil;
		}

		capturedImage = c;
		CVPixelBufferRetain(capturedImage);
	}
	@finally
	{
		[capturedImageLock unlock];
	}

	CGSize size = CVImageBufferGetDisplaySize(capturedImage);

	// If VNC Server is running with different screen size, stop it and destroy it
	if ((mVNCServer != nil) && ([mVNCServer isSizeDifferent:size]))
	{
		[mVNCServer stop];
		mVNCServer = nil;
	}
	
	// If VNC Server is not initialized, initialize one
	if (mVNCServer == nil)
	{
		mVNCServer = [[VNCServer new] init:^(){return [self takeImage];} address:socketAddress size:size downScaleFactor:1];
		if (mVNCServer == nil) return;
	}
	
	// If VNC Server is not started, start it
	if (![mVNCServer isStarted])
	{
		[mVNCServer start];
	}
	
	[mVNCServer imageReady];
}

-(int)takeImage
{
	CVImageBufferRef image;

	[capturedImageLock lock];
	@try
	{
		if (capturedImage == nil) return 0;

		image = capturedImage;
		capturedImage = nil;
	}
	@finally
	{
		[capturedImageLock unlock];
	}

	OSType capturedImagePixelFormat = CVPixelBufferGetPixelFormatType(image);
	switch (capturedImagePixelFormat) {
		case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
			[mVNCServer pushPixels_420YpCbCr8BiPlanarFullRange:image];
			break;

		default:
			NSLog(@"CVIO Captured image is in an unknown format: %08X", capturedImagePixelFormat);
			break;
	};

	CVPixelBufferRelease(image);
	return 0;
}

///

- (NSString *)getState
{
	return [SeaCatClient getState];
}

- (NSString *)getClientTag
{
	return [SeaCatClient getClientTag];
}

- (NSString *)getClientId
{
	return [SeaCatClient getClientId];
}

@end

