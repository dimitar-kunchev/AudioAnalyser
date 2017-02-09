//
//  AASignalGeneratorControlViewController.m
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "AASignalGeneratorControlViewController.h"

@interface AASignalGeneratorControlViewController ()

@end

@implementation AASignalGeneratorControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)toggleEnabled:(id)sender {
    if ([[AAAudioManager manager] outputEnabled]) {
        [[AAAudioManager manager] setOutputEnabled:NO];
        [self.toggleEnabledButton setTitle:@">" forState:UIControlStateNormal];
    } else {
        [[AAAudioManager manager] setOutputEnabled:YES];
        [self.toggleEnabledButton setTitle:@"II" forState:UIControlStateNormal];
    }
}

- (IBAction)amplitudeChanged:(id)sender {
    [[[AAAudioManager manager] signalGenerator] setAmplitude:self.amplitudeSlider.value];
}

@end
