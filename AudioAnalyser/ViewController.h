//
//  ViewController.h
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>

#import "AAOscilloscopeView.h"
#import "AASpectrumView.h"

#import "AAAudioManager.h"
#import "CommonHelpers.h"

#define kNumberBuffers 4

@interface ViewController : UIViewController <AVCaptureAudioDataOutputSampleBufferDelegate> {
//    AVCaptureSession *captureSession;
//    AVCaptureAudioDataOutput * audioCaptureOutuput;
//    dispatch_queue_t samplingQueue;
    
//    char * audioBuffer;
//    size_t audioBufferSize;
//    NSLock * audioBufferLock;
    
    ///
}

@property (nonatomic, retain) IBOutlet AAOscilloscopeView * oscilloscopeView;
@property (nonatomic, retain) IBOutlet AASpectrumView * spectrumView;

@end

