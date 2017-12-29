//
//  ViewController.m
//  app
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import "MainViewController.h"
#import "CatVisionIO/CatVisionIO.h"
#import "SeaCatClient/SeaCatClient.h"

//

@interface MainViewController ()

@end

@implementation MainViewController

///

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[CatVision sharedInstance]; // Initialize CatVision.io SDK
	[SeaCatClient addObserver:self selector:@selector(onStateChanged) name:SeaCat_Notification_StateChanged];
	[SeaCatClient addObserver:self selector:@selector(onClientIdChanged) name:SeaCat_Notification_ClientIdChanged];
	
	[self onStateChanged];
	[self onClientIdChanged];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[SeaCatClient removeObserver:self];
	[super viewWillDisappear:animated];
}

- (void)onStateChanged
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		self.StateLabel.text = [SeaCatClient getState];
	}];
}

- (void)onClientIdChanged
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		self.ClientTagLabel.text = [[CatVision sharedInstance] getClientTag];
	}];
}

///

- (IBAction)onSharingTrigger:(id)sender {
	if ([self.shareSwitch isOn])
	{
		[[CatVision sharedInstance] start];
	}
	else
	{
		[[CatVision sharedInstance] stop];
	}
}

@end
