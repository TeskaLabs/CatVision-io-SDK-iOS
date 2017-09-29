//
//  VNCServer.m
//  VNCServer
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import "VNCServer.h"
#include "rfb/rfb.h"
#include <sys/un.h>

// We need a word to capture a pixel (aka 16bit color or actually 15bit)
#define BPP      (2)

static int rfbListenOnUNIXPort(const char * path);

@implementation VNCServer {
	int myWidth;
	int myHeight;
	int myLineStride; // 'Real width' including a border
	int myXOffset;

	size_t myFbLength;
	void * myFb;
	
	rfbScreenInfoPtr myServerScreen;
	
	int serverShutdown;
	int imageReady;
	
	NSMutableString *mySockAddress;
}

- (id)init:(int)width height:(int)height
{
	self = [super init];
	if (self == nil) return nil;

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSMutableString *mySockAddress = [[paths objectAtIndex:0] mutableCopy];
	[mySockAddress appendString:@"/vnc.s"]; //TODO: socket name can be more unique - it will allow to start more than one VNC server if needed

	self->serverShutdown = 0;
	self->imageReady = 0;

	self->myWidth = width;
	self->myHeight = height;
	self->myLineStride = (self->myWidth + 7) & ~7; // Round to next 8
	self->myXOffset = (self->myLineStride - self->myWidth) / 2; // Put picture in the middle
	self->myFbLength = self->myLineStride * (self->myHeight + 1) * BPP;

	self->myFb = malloc(self->myFbLength);
	if (self->myFb == NULL)
	{
		NSLog(@"Failed to allocate memory for VNC server");
		return nil;
	}

	int argc=1;
	self->myServerScreen = rfbGetScreen(&argc, NULL, self->myLineStride, self->myHeight, 5, 3, BPP);
	if (self->myServerScreen ==  NULL)
	{
		NSLog(@"Failed to allocate a VNC server screen");
		free(self->myFb);
		self->myFb = NULL;
		return nil;
	}

	self->myServerScreen->desktopName = "CatVision.io client"; //TODO: Name of the client to be passed from SeaCat
	self->myServerScreen->frameBuffer = self->myFb;
	self->myServerScreen->alwaysShared = (1==1);

	self->myServerScreen->inetdSock = -1;
	self->myServerScreen->autoPort = 0;
	self->myServerScreen->port=0;
	self->myServerScreen->ipv6port=0;
	self->myServerScreen->udpPort=0;
	self->myServerScreen->httpInitDone = (1==1);
	
	self->myServerScreen->newClientHook = NULL;
	self->myServerScreen->ptrAddEvent = NULL;
	self->myServerScreen->kbdAddEvent = NULL;
	self->myServerScreen->kbdReleaseAllKeys = NULL;
	self->myServerScreen->setXCutText = NULL;
	
	rfbInitServer(self->myServerScreen);

	self->myServerScreen->listenSock = rfbListenOnUNIXPort([mySockAddress UTF8String]);
	if (self->myServerScreen->listenSock < 0)
	{
		NSLog(@"Failed to open a UNIX socket for a VNC server screen");
		rfbScreenCleanup(self->myServerScreen);
		self->myServerScreen = NULL;
		free(self->myFb);
		self->myFb = NULL;
		return nil;
	}

	FD_SET(self->myServerScreen->listenSock, &(self->myServerScreen->allFds));
	self->myServerScreen->maxFd = self->myServerScreen->listenSock;

	// Preset framebuffer with black color
	uint16_t * buffer = self->myFb;
	for(int y=0; y<self->myHeight; y+=1)
	{
		for(int x=0; x<self->myLineStride; x+=1)
		{
			buffer[(y*self->myLineStride)+x] = 0;
		}
	}

	return self;
}

-(void)dealloc {
	
	if ([mySockAddress length] > 0)
	{
		unlink([mySockAddress UTF8String]);
	}
	if (self->myServerScreen != NULL)
	{
		rfbScreenCleanup(self->myServerScreen);
		self->myServerScreen = NULL;
	}
	if (self->myFb != NULL)
	{
		free(self->myFb);
		self->myFb = NULL;
	}
}

- (void)run
{
	//TODO: Prevent double-run
	[NSThread detachNewThreadSelector: @selector(_run) toTarget:self withObject:NULL];
}

- (void)_run
{
	while (rfbIsActive(self->myServerScreen))
	{
		if (self->imageReady != 0)
		{
			self->imageReady = 0;
/*
			 int ret = takeImage();
			if (ret != 0)
			{
				// takeImage() requested VNC server shutdown
				serverShutdown = 1;
				rfbShutdownServer(serverScreen, (1==1));
				serverShutdown = 2;
				continue;
			}
*/
		}
		
		long usec = self->myServerScreen->deferUpdateTime*1000;
		rfbProcessEvents(self->myServerScreen, usec);
		
		if (serverShutdown == 1)
		{
			rfbShutdownServer(self->myServerScreen, (1==1));
			serverShutdown = 2;
		}
	}
}


- (int)shutdown
{
	return 0;
}

@end


static int rfbListenOnUNIXPort(const char * path)
{
	char buffer[2048]; // The path can be longer than `struct sockaddr_un`
	struct sockaddr_un * addr  = (struct sockaddr_un *)buffer;
	int sock;
	
	unlink(path);
	memset(addr, 0, sizeof(struct sockaddr_un));
	addr->sun_family = AF_UNIX;
	strcpy(addr->sun_path, path);
	socklen_t len = (socklen_t)strlen(path) + 1 + sizeof(addr->sun_family);
	
	if ((sock = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
	{
		NSLog(@"socket() failed %d", errno);
		return -1;
	}
	
	if (bind(sock, (struct sockaddr *)addr, len) < 0)
	{
		NSLog(@"bind() failed %d on '%s'", errno, path);
		close(sock);
		return -1;
	}
	
	if (listen(sock, 4) < 0)
	{
		NSLog(@"listen() failed %d", errno);
		close(sock);
		return -1;
	}
	
	return sock;
}
