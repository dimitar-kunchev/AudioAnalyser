//
//  ViewController.m
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "ViewController.h"

#define	SizeOf32(X)	((UInt32)sizeof(X))

//#define SWEEP_SIM

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self.oscilloscopeView setBytesPerSample:2];
    
    //[self setupAudioSim];
    
    [[[AAAudioManager manager] inputReader] setDelegate:self.spectrumView];
    
    [[AAAudioManager manager] setOutputEnabled:NO];
    [[AAAudioManager manager] setUseSimulatedInput:NO];
    [[AAAudioManager manager] setInputEnabled:YES];
    
    /*
    if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionGranted) {
        NSLog(@"Audio permissions already granted");
        [self setupAudioInput];
    } else {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                [self setupAudioInput];
            }
        }];
    }*/
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
- (void) setupAudioInput {
    NSLog (@"Sample rate is: %f", [[AVAudioSession sharedInstance] sampleRate]);
    NSLog (@"Buffer length is: %f", [[AVAudioSession sharedInstance] IOBufferDuration]);
    NSLog (@"Available modes: %@", [[AVAudioSession sharedInstance] availableModes]);
    NSLog (@"Available Inputs: %@", [[AVAudioSession sharedInstance] availableInputs]);
    //AVAudioRecorder * ar = [[AVAudioRecorder alloc] init];
    
    captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSLog(@"Selected audio device: %@", audioCaptureDevice);
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput) {
        [captureSession addInput:audioInput];
        NSLog(@"Audio input ready");
    } else {
        NSLog(@"Error preparing audio input: %@", error.localizedDescription);
    }
    
    audioCaptureOutuput = [[AVCaptureAudioDataOutput alloc] init];
    //[audioCaptureOutuput setSampleBufferDelegate:self queue:samplingQueue];
    samplingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [audioCaptureOutuput setSampleBufferDelegate:self queue:samplingQueue];
    if ([captureSession canAddOutput:audioCaptureOutuput]) {
        [captureSession addOutput:audioCaptureOutuput];
    } else {
        NSLog(@"Cannot add output");
    }
    
    /// Prepare the audio buffer
    // @TODO: from sample rate and etc we must figure the size
    audioBufferSize = 1024*1024;
    audioBuffer = malloc(audioBufferSize);
    
    /// Prepare the semaphore
    audioBufferLock = [[NSLock alloc] init];
    
    NSLog(@"session start!");
    [captureSession startRunning];
    
}*/

//- (void) setupAudioSim {
//    [self performSelectorInBackground:@selector(audioSimulator) withObject:nil];
//}

#ifdef SWEEP_SIM
/*
- (void) audioSimulator {
    float t = 0;
    float frequencyStart = 20;
    float frequencyEnd = 20000;
    float frequencyCurrent = frequencyStart;
    float frequencyStep = 40;
    float frequencyStepDuration = 0.2; // this defines how long we spend at each step! Total freq sweep time is frequencyStepDuration * (frequencyEnd - frequencyStart)/frequencyStep
    float frequencyStepCurrentTime = 0;
    
    int sampleRate = 44100;
    int bufferLength = 1024; // ints, not bytes
    int gain = 1000;
    float bufferDuration = (float)bufferLength / sampleRate;
    int16_t * buffer = malloc(sizeof(int16_t) * bufferLength);
    
    while (true) {
        @autoreleasepool {
            t = t - (long)t;
            
            frequencyStepCurrentTime += bufferDuration;
            if (frequencyStepCurrentTime > frequencyStepDuration) {
                frequencyStepCurrentTime = 0;
                frequencyCurrent += frequencyStep;
                if (frequencyCurrent > frequencyEnd) {
                    frequencyCurrent -= frequencyEnd;
                }
            }

            float twoPiF = 2 * M_PI * frequencyCurrent;
            for (int i = 0; i < bufferLength; i ++) {
                buffer[i] = sin(twoPiF * (t + bufferDuration * i/bufferLength)) * gain;
            }
            t += bufferDuration;
            [self emitAudioBuffer:buffer size:bufferLength * sizeof(uint16_t)];
            sleep(bufferDuration);
        }
    }
}
*/
#else
/*
- (void) audioSimulator {
    float t = 0;
    float frequency1 = 2000;
    float frequency2 = 1500;
    int bufferLength = 1024;
    int gain1 = 500;
    int gain2 = 0;
    float bufferDuration = (float)bufferLength / 44100;
    int16_t * buffer = malloc(sizeof(int16_t) * bufferLength);
    
    float twoPiF1 = 2 * M_PI * frequency1;
    float twoPiF2 = 2 * M_PI * frequency2;
    while (true) {
        @autoreleasepool {
            t = t - (long)t;
            for (int i = 0; i < bufferLength; i ++) {
                buffer[i] = sin(twoPiF1 * (t + bufferDuration * i/bufferLength)) * gain1;
                buffer[i] += sin(twoPiF2 * (t + bufferDuration * i/bufferLength)) * gain2;
            }
            t += bufferDuration;
            [self emitAudioBuffer:buffer size:bufferLength * sizeof(uint16_t)];
            sleep(bufferDuration);
        }
    }
}*/
#endif

@end

