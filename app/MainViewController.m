//
//  ViewController.m
//  app
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import "MainViewController.h"
#import "CatVisionIO/CatVisionIO.h"

//

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}


- (IBAction)onStart:(id)sender {
	[[CatVision sharedInstance] start];
}

@end
