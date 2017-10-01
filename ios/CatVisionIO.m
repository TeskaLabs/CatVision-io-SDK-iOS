//
//  CatVision.m
//  CatVision.io SDK for iOS
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SeaCatClient/SeaCatClient.h>
#import "CatVisionIO.h"
#import "VNCServer.h"

@implementation CatVision {
	VNCServer * mVNCServer;
	BOOL mSeaCatCofigured;
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

	[SeaCatClient setApplicationId:@"com.teskalabs.cvio"];
	[SeaCatClient setLogMask:SC_LOG_FLAG_DEBUG_GENERIC];

	return self;
}

- (BOOL)start
{
	if (mVNCServer == nil)
	{
		mVNCServer = [[VNCServer new] init:800 height:600];
		if (mVNCServer == nil) return NO;
	}
	[mVNCServer run];
	
	if (mSeaCatCofigured == NO) //TODO: if (![SeaCatClient isConfigured])
	{
		[SeaCatClient configureWithCSRDelegate:self];
		[SeaCatClient reset];
		mSeaCatCofigured = YES;
	}
	
	return YES;
}

// Submit CSR
-(bool)submit:(NSError **)out_error
{
	NSLog(@"submit!!!!");

	NSString * APIKeyId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CVIOApiKeyId"];
	if (APIKeyId == nil)
	{
		NSLog(@"CatVision.io API key (CVIOApiKeyId) not provided. See https://docs.catvision.io/get-started/api-key.html");
		return nil;
	}

	SCCSR * csr = [[SCCSR alloc] init];
	[csr setOrganization:@"TODO"]; //TODO: getPackageName()
	[csr setOrganizationUnit:APIKeyId];
	return [csr submit:out_error];
}


@end

