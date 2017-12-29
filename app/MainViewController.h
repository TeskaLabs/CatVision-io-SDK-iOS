//
//  ViewController.h
//  app
//
//  Created by Ales Teska on 28.9.17.
//  Copyright © 2017 TeskaLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *shareSwitch;
- (IBAction)onSharingTrigger:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *ClientTagLabel;
@property (weak, nonatomic) IBOutlet UILabel *StateLabel;

@end

