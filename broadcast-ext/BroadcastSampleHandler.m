//
//  SampleHandler.m
//  broadcast-ext
//
//  Created by Ales Teska on 3.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//


#import "BroadcastSampleHandler.h"
#import <CatVisionIO/CatVisionIO.h>
#import "BroadcastSampleSource.h"

@implementation BroadcastSampleHandler {
	BroadcastSampleSource * source;
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
	
	source = [[BroadcastSampleSource new] init];
	CatVision * cvio = [CatVision sharedInstance];
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
            [[source delegate]handleSourceBuffer:sampleBuffer sampleType:sampleBufferType];
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
