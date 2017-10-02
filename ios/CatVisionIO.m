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
#import "CatVisionIO.h"
#import "VNCServer.h"
#import "ReplayKitSource/CVIOReplayKitSource.h"

@implementation CatVision {
	NSString * socketAddress;
	VNCServer * mVNCServer;
	BOOL mSeaCatCofigured;
	BOOL mStarted;
	CVIOSeaCatPlugin * plugin;	
	id<CVIOSource> source;

	UIImage * capturedImage;
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
	mSeaCatCofigured = NO;
	mStarted = NO;

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSMutableString *addr = [[paths objectAtIndex:0] mutableCopy];
	[addr appendString:@"/vnc.s"]; //TODO: socket name can be more unique - it will allow to start more than one VNC server if needed
	socketAddress = [addr copy];
	
	[SeaCatClient setApplicationId:@"com.teskalabs.cvio"];
	//This is to enable SeaCat debug logging [SeaCatClient setLogMask:SC_LOG_FLAG_DEBUG_GENERIC];
	plugin = [[CVIOSeaCatPlugin alloc] init:5900];
	
	source = [[CVIOReplayKitSource alloc] init:self];
	capturedImage = nil;
	
	return self;
}

- (BOOL)start
{
	mStarted = YES;
	
	if (mVNCServer == nil)
	{
		//TODO: Get current screen size
		mVNCServer = [[VNCServer new] init:self address:socketAddress width:640 height:1136];
		if (mVNCServer == nil) return NO;
	}
	[mVNCServer start];
	
	// VNC Server started
	if (mSeaCatCofigured == NO) //TODO: if (![SeaCatClient isConfigured])
	{
		[SeaCatClient configureWithCSRDelegate:self];
		[plugin configureSocket:socketAddress];
		mSeaCatCofigured = YES;
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

	return YES;
}

// Submit CSR
-(bool)submit:(NSError **)out_error
{
	NSString * APIKeyId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CVIOApiKeyId"];
	if (APIKeyId == nil)
	{
		NSLog(@"CatVision.io API key (CVIOApiKeyId) not provided. See https://docs.catvision.io/get-started/api-key.html");
		return nil;
	}

	NSBundle *bundle = [NSBundle mainBundle];
	NSDictionary *info = [bundle infoDictionary];

	SCCSR * csr = [[SCCSR alloc] init];
	[csr setOrganization:[info objectForKey:(NSString*)kCFBundleIdentifierKey]];
	[csr setOrganizationUnit:APIKeyId];
	return [csr submit:out_error];
}

-(void)handleSourceBuffer:(CMSampleBufferRef)sampleBuffer sampleType:(RPSampleBufferType)sampleType
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
	CIContext *temporaryContext = [CIContext contextWithOptions:nil];
	CGImageRef videoImage = [temporaryContext
							 createCGImage:ciImage
							 fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
	
	capturedImage = [[UIImage alloc] initWithCGImage:videoImage];
	CGImageRelease(videoImage);
	[mVNCServer imageReady];
}

-(int)takeImage
{
	if (capturedImage == nil) return 0;
	
    CGImageRef image = [capturedImage CGImage];
    CGDataProviderRef provider = CGImageGetDataProvider(image);
    CFDataRef data = CGDataProviderCopyData(provider);
	
	const unsigned char * buffer =  CFDataGetBytePtr(data);
	ssize_t buffer_len = CFDataGetLength(data);
	
	[mVNCServer pushPixelsRGBA8888:buffer length:buffer_len row_stride:640*4];
	
	CGImageRelease(image);
	
	return 0;
}

@end

