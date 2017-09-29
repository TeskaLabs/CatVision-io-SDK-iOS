//
//  ViewController.m
//  app
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import "MainViewController.h"
#import "VNCServer.h"

@interface MainViewController ()

@end

@implementation MainViewController {
	VNCServer * vncserver;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
		
	vncserver = [[VNCServer alloc] init:800 height:600];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)onStart:(id)sender {
	[vncserver run];
}

@end
