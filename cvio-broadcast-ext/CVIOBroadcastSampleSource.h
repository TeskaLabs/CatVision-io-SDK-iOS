//
//  CVIOBroadcastSampleSource.h
//  cvio-broadcast-ext
//
//  Created by Ales Teska on 8.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <ReplayKit/ReplayKit.h>
#import <CatVisionIO/CatVisionIO.h>

@interface CVIOBroadcastSampleSource : NSObject <CVIOSource>

@property (readonly) id<CVIOSourceDelegate> delegate;

-(instancetype)init:(id<CVIOSourceDelegate>)delegate;

-(void)start;
-(void)stop;

@end
