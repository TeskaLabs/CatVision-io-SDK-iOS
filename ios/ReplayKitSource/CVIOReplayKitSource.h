//
//  CVIOReplayKitSource.h
//  ios
//
//  Created by Ales Teska on 1.10.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

@interface CVIOReplayKitSource : NSObject <CVIOSource>

@property (readonly) id<CVIOSourceDelegate> delegate;

-(instancetype)init:(id<CVIOSourceDelegate>)delegate;

-(void)start;
-(void)stop;

@end
