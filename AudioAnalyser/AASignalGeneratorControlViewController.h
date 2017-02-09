//
//  AASignalGeneratorControlViewController.h
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AAAudioManager.h"

@interface AASignalGeneratorControlViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton * toggleEnabledButton;
@property (nonatomic, retain) IBOutlet UISlider * amplitudeSlider;

- (IBAction)toggleEnabled:(id)sender;
- (IBAction)amplitudeChanged:(id)sender;

@end
