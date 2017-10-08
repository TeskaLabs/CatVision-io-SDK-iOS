//
//  CVIOBroadcastSampleHandler.m
//  cvio-broadcast-ext
//
//  Created by Ales Teska on 3.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//


#import "CVIOBroadcastSampleHandler.h"
#import <CatVisionIO/CatVisionIO.h>
#import "CVIOBroadcastSampleSource.h"

@implementation CVIOBroadcastSampleHandler {
	CVIOBroadcastSampleSource * source;
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
	CatVision * cvio = [CatVision sharedInstance];
	source = [[CVIOBroadcastSampleSource new] init:cvio];
	[cvio setSource:source];
	[cvio start];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            [[source delegate] handleSourceBuffer:sampleBuffer sampleType:sampleBufferType];
            break;

/* Not used yet
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;

        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
*/
        default:
            break;
    }
}

@end
