//
//  CVIOInterfaces.h
//  ios
//
//  Created by Ales Teska on 2.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

@protocol CVIOSourceDelegate <NSObject>
-(void)handleSourceBuffer:(CMSampleBufferRef)sampleBuffer sampleType:(RPSampleBufferType)sampleType;
@end

@protocol CVIOSource <NSObject>
-(void)start;
-(void)stop;

@end
