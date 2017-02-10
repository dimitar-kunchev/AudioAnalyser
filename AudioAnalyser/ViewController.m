//
//  ViewController.m
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionGranted) {
        NSLog(@"Audio permissions already granted");
        [self setupAudio];
    } else {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                [self setupAudio];
            }
        }];
    }
}

- (void) setupAudio {
    NSError * error = nil;
    /// Add to the options mixing and ducking of needed!
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                                 mode:AVAudioSessionModeMeasurement
                                              options:AVAudioSessionCategoryOptionAllowAirPlay | AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                                error:&error]) {
        NSLog(@"Could not set Audio Session properties! Error: %@", error.localizedDescription);
    }
    [[[AAAudioManager manager] inputReader] setDelegate:self.spectrumView];
    
    [[AAAudioManager manager] setOutputEnabled:NO];
    [[AAAudioManager manager] setUseSimulatedInput:NO];
    [[AAAudioManager manager] setInputEnabled:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

