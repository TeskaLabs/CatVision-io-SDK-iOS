//
//  CVIOSeaCatCSR.m
//  ios
//
//  Created by Ales Teska on 29.12.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CVIOSeaCatCSR.h"

@implementation CVIOSeaCatCSR

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

@end
