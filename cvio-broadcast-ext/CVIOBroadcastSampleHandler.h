//
//  CVIOBroadcastSampleHandler.h
//  cvio-broadcast-ext
//
//  Created by Ales Teska on 3.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <ReplayKit/ReplayKit.h>

@interface CVIOBroadcastSampleHandler : RPBroadcastSampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo;
- (void)broadcastPaused;
- (void)broadcastResumed;
- (void)broadcastFinished;
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;

@end
