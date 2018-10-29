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

///////

static enum rfbNewClientAction newClientHook(rfbClientPtr cl)
{
	//TODO: This ...
	NSLog(@"New VNC client accepted.");
	return RFB_CLIENT_ACCEPT;
}

static void ptrAddEvent(int buttonMask, int x, int y, rfbClientPtr cl)
{
	//TODO: This ...
}

static void kbdAddEvent(rfbBool down, rfbKeySym keySym, struct _rfbClientRec* cl)
{
	//TODO: This ...
}

static void kbdReleaseAllKeys(struct _rfbClientRec* cl)
{
	//TODO: This ...
}

static void setXCutText(char* str,int len, struct _rfbClientRec* cl)
{
	//TODO: This ...
}

/////

@implementation VNCServer {
	CGSize mySize;
	size_t myWidth;
	size_t myHeight;
	size_t myLineStride; // 'Real width' including a border
	size_t myXOffset;
	size_t myDownScaleFactor;

	size_t myFbLength;
	void * myFb;
	
	NSString * mySocketAddress;
	NSThread * myThread;
	
	NSTimeInterval myLastScreenUpdate;
	
	rfbScreenInfoPtr myServerScreen;
	
	int runPhase; // 0 .. idle, 1 .. starting, 2 .. running, 3 .. stopping
	int imageReady;
	
	int (^takeImageHandler)(void);
}

- (id)init:(int(^)(void))takeImage address:(NSString *)socketAddress size:(CGSize)size downScaleFactor:(int)downScaleFactor
{
	self = [super init];
	if (self == nil) return nil;

	self->takeImageHandler = [takeImage copy];
	self->mySocketAddress = socketAddress;
	self->myThread = nil;
	self->runPhase = 0;
	self->imageReady = 0;

	self->mySize = size;
	self->myWidth = size.width;
	self->myHeight = size.height;
	self->myDownScaleFactor = downScaleFactor;
	self->myWidth >>= downScaleFactor;
	self->myHeight >>= downScaleFactor;

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
	
	self->myServerScreen->newClientHook = newClientHook;
	self->myServerScreen->ptrAddEvent = ptrAddEvent;
	self->myServerScreen->kbdAddEvent = kbdAddEvent;
	self->myServerScreen->kbdReleaseAllKeys = kbdReleaseAllKeys;
	self->myServerScreen->setXCutText = setXCutText;
	
	rfbInitServer(self->myServerScreen);

	self->myServerScreen->listenSock = rfbListenOnUNIXPort([socketAddress UTF8String]);
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
	// Preset framebuffer with CatVision.io blue color (#21323e)
	const uint16_t r = 0x21 >> 3;
	const uint16_t g = 0x32 >> 3;
	const uint16_t b = 0x3e >> 3;
	const uint16_t p = (b << 10) | (g << 5) | r;

	uint16_t * buffer = self->myFb;
	for(int y=0; y<self->myHeight; y+=1)
	{
		for(int x=0; x<self->myLineStride; x+=1)
		{
			buffer[(y*self->myLineStride)+x] = p;
		}
	}

	return self;
}

-(void)dealloc {
	
	if ([self->mySocketAddress length] > 0)
	{
		unlink([self->mySocketAddress UTF8String]);
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

- (BOOL)isSizeDifferent:(CGSize)size
{
	return ((size.height != mySize.height) || (size.width != mySize.width));
}

- (BOOL)isStarted
{
	return (runPhase != 0);
}

- (void)start
{
	if (self->myThread != nil)
	{
		NSLog(@"VNCServer is already started");
		return;
	}

	self->myLastScreenUpdate = [[NSDate date] timeIntervalSince1970];
	self->runPhase = 1;
	self->myThread = [[NSThread alloc] initWithTarget:self selector:@selector(_run) object:nil];
	[self->myThread setName:@"CVIOVNCServerThread"];
	[self->myThread start];
}

- (void)_run
{
	self->runPhase = 2;
	
	while (rfbIsActive(self->myServerScreen))
	{
		if (self->imageReady != 0)
		{
			self->imageReady = 0;

			int ret = takeImageHandler();
			if (ret != 0)
			{
				// takeImage() requested VNC server shutdown
				self->runPhase = 3;
			}

		}
		
		long usec = self->myServerScreen->deferUpdateTime*1000;
		rfbProcessEvents(self->myServerScreen, usec);

		if (self->runPhase == 3)
		{
			rfbShutdownServer(self->myServerScreen, (1==1));
		}
	}
	
	self->runPhase = 0;
	self->myThread = nil;
}


- (void)stop
{
	if (self->runPhase == 2) self->runPhase = 3;
}


- (void)imageReady
{
	self->imageReady += 1;
}

- (void)_touch
{
	self->myLastScreenUpdate = [[NSDate date] timeIntervalSince1970];
}


- (void)tick
{
	int deltat = [[NSDate date] timeIntervalSince1970] - self->myLastScreenUpdate;
	if (deltat > 30) // If we don't see the update for 30 seconds, issue one artifically
	{
		rfbMarkRectAsModified(myServerScreen, 0, 0, 1, 1);
		[self _touch];
	}
}

- (void)pushPixels_RGBA8888:(const unsigned char *)buffer length:(ssize_t)len row_stride:(int)s_stride
{
	// This needs to be super-optimized!
	// TODO: See NEON/SIMD optimisations in libyuv https://chromium.googlesource.com/libyuv/libyuv/+/master/source/row_neon64.cc
	uint8_t * s = (uint8_t *)buffer;
	uint16_t * t = (uint16_t *)myServerScreen->frameBuffer;
	
	int max_x=-1,max_y=-1, min_x=99999, min_y=99999;
	
	for (int y=0; y < myHeight; y+=1)
	{
		int tpos = (y * myLineStride) + myXOffset;
		const int spos = y * s_stride;
		
		for (int x=0; x < myWidth; x+=1, tpos+=1)
		{
			const int si = spos + (x << 2); //2 is for 32bit
			if ((si+2) >= len)
			{
				NSLog(@"VNCServer buffer overflow: %d vs %lu %dx%d spos:%d", si+2, len, x, y, spos);
				return;
			}
			
			const uint16_t r = s[si+0] >> 3;
			const uint16_t g = s[si+1] >> 3;
			const uint16_t b = s[si+2] >> 3;
			
			const uint16_t p = (b << 10) | (g << 5) | r;
			
			if (t[tpos] == p) continue; // No update needed
			t[tpos] = p;
			
			if (x > max_x) max_x = x;
			if (x < min_x) min_x = x;
			if (y > max_y) max_y = y;
			if (y < min_y) min_y = y;
		}
	}
	
	if (max_x == -1) return; // No update needed
	
	rfbMarkRectAsModified(myServerScreen, myXOffset + min_x, min_y, myXOffset + max_x + 1, max_y + 1);
	[self _touch];
}

- (void)pushPixels_420YpCbCr8BiPlanarFullRange:(CVImageBufferRef)imageBuffer
{
	// This needs to be super-optimized!
	// TODO: See NEON/SIMD optimisations in libyuv https://chromium.googlesource.com/libyuv/libyuv/+/master/source/row_neon64.cc
	// Insprired by https://stackoverflow.com/questions/8838481/kcvpixelformattype-420ypcbcr8biplanarfullrange-frame-to-uiimage-conversion

	uint16_t * t = (uint16_t *)myServerScreen->frameBuffer;
	int max_x=-1,max_y=-1, min_x=99999, min_y=99999;

	CVPixelBufferLockBaseAddress(imageBuffer,0);
	
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	uint8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
	size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
	uint8_t *cbCrBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
	size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
	
	for(int y = 0; y < height; y+=(1 << myDownScaleFactor))
	{
		uint8_t *yBufferLine = &yBuffer[y * yPitch];
		uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
		
		size_t tpos = ((y >> myDownScaleFactor) * myLineStride) + myXOffset;
		
		for(int x = 0; x < width; x+=(1 << myDownScaleFactor), tpos+=1)
		{
			int16_t cy = yBufferLine[x];
			int16_t cb = cbCrBufferLine[x & ~1] - 128;
			int16_t cr = cbCrBufferLine[x | 1] - 128;
			
			int16_t r = (int16_t)roundf( cy + cr *  1.4 );
			int16_t g = (int16_t)roundf( cy + cb * -0.343 + cr * -0.711 );
			int16_t b = (int16_t)roundf( cy + cb *  1.765);
		
			// Clamp and convert to RGB_555
			r = ((r>255?255:(r<0?0:r)) >> 3) & 0x001F;
			g = ((g>255?255:(g<0?0:g)) >> 3) & 0x001F;
			b = ((b>255?255:(b<0?0:b)) >> 3) & 0x001F;
			const uint16_t p = (b << 10) | (g << 5) | r;
			
			if (t[tpos] == p) continue; // No update needed
			t[tpos] = p;
			
			if (x > max_x) max_x = x;
			if (x < min_x) min_x = x;
			if (y > max_y) max_y = y;
			if (y < min_y) min_y = y;

		}
	}

	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	if (max_x == -1) return; // No update needed
	
	rfbMarkRectAsModified(myServerScreen,
		  (int) myXOffset + (min_x >> myDownScaleFactor),
		  min_y >> myDownScaleFactor,
		  (int) myXOffset + (max_x >> myDownScaleFactor) + 1,
		  (max_y >> myDownScaleFactor) + 1
    );
	[self _touch];
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
