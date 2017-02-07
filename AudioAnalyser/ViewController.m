//
//  ViewController.m
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "ViewController.h"

#define	SizeOf32(X)	((UInt32)sizeof(X))

#define SWEEP_SIM

NSString *NSStringFromOSStatus(OSStatus errCode);

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData);

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.oscilloscopeView setBytesPerSample:2];
    
    //[self setupAudioSim];
    [self attemptAUInput];
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

- (void) attemptAUInput {
    OSStatus status;
    
    AudioUnitElement kInputBusNumber = 1;
    AudioUnitElement kOutputBusNumber = 0;
    
    AudioComponentDescription defaultInputDescription;
    defaultInputDescription.componentType = kAudioUnitType_Output;
    defaultInputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultInputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultInputDescription.componentFlags = 0;
    defaultInputDescription.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &defaultInputDescription);
    status = AudioComponentInstanceNew(inputComponent, &_audioUnit);
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBusNumber,
                                  &flag,
                                  sizeof(flag));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (enable recording)");
        return;
    }
    // Disable playback IO
    flag = 0;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBusNumber,
                                  &flag,
                                  sizeof(flag));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (disable output)");
        return;
    }
    
    // Describe format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = 44100.00;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerPacket     = 2;
    audioFormat.mBytesPerFrame      = 2;
    
    // Apply format
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBusNumber,
                                  &audioFormat,
                                  sizeof(audioFormat));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (format)");
        return;
    }
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void*)self;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBusNumber,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (record callback): %d", status);
        return;
    }
    status = AudioUnitInitialize(_audioUnit);
    if (status != noErr) {
        NSLog(@"Error in AudioUnitInitialize: %@", NSStringFromOSStatus(status));
        return;
    }
    
    status = AudioOutputUnitStart(_audioUnit);
    if (status != noErr) {
        NSLog(@"Error in AudioUnitStart: %@", NSStringFromOSStatus(status));
        return;
    } else {
        NSLog(@"AU started");
    }
}

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
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //CMTime t = CMSampleBufferGetDuration (sampleBuffer);
    if (sampleBuffer != NULL) {
        OSErr err;
        
        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        //CAStreamBasicDescription sampleBufferASBD(*CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription));
        const AudioStreamBasicDescription * streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        if (streamBasicDescription->mFormatID != kAudioFormatLinearPCM) {
            NSLog(@"Not PCM audio!");
            return;
        }
        
        CMItemCount numberOfSamples = CMSampleBufferGetNumSamples(sampleBuffer);
        if (numberOfSamples == 0) {
            NSLog(@"Zero samples");
            return;
        }
        
        // Prepare the memory for the data in buffer lists
        // I think there is something wrong with this code, relating to how channels are handled in the buffer list. Perhaps the general idea is that we should have multiple ABLs - one per channel?
        size_t bufferListSizeNeededOut;
        size_t ABLsSize = [self calculateABLByteSize:streamBasicDescription->mChannelsPerFrame];
        CMBlockBufferRef blockBufferOut = nil;
        AudioBufferList * currentInputAudioBufferList = (AudioBufferList *) (calloc(1, ABLsSize));
        currentInputAudioBufferList->mNumberBuffers = streamBasicDescription->mChannelsPerFrame;
        err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                      &bufferListSizeNeededOut,
                                                                      currentInputAudioBufferList,
                                                                      ABLsSize,
                                                                      kCFAllocatorSystemDefault,
                                                                      kCFAllocatorSystemDefault,
                                                                      kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                      &blockBufferOut);
        
        if (err == noErr) {
            /// Process
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSLog(@"Stream description: %ld sample rate, %d bits per channel, %d channels per frame, %d frames per packet",
                      lround(streamBasicDescription->mSampleRate),
                      streamBasicDescription->mBitsPerChannel,
                      streamBasicDescription->mChannelsPerFrame,
                      streamBasicDescription->mFramesPerPacket
                      );
                for (int i = 0; i < streamBasicDescription->mChannelsPerFrame; i ++) {
                    NSLog(@"ABL %d: %d buffer", i, currentInputAudioBufferList[i].mNumberBuffers);
                    for (int j = 0; j < currentInputAudioBufferList[i].mNumberBuffers; j ++) {
                        NSLog(@"  Buffer size: %d", currentInputAudioBufferList[i].mBuffers[j].mDataByteSize);
                    }
                }
            });
            
            [self emitAudioBuffer:currentInputAudioBufferList[0].mBuffers[0].mData size:currentInputAudioBufferList[0].mBuffers[0].mDataByteSize];
            
            CFRelease(blockBufferOut);
            free (currentInputAudioBufferList);
        } else {
            NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed! (%ld)", (long)err);
        }
    } else {
        NSLog(@"NULL buffer?!");
    }
}

- (UInt32) calculateABLByteSize:(UInt32) inNumberBuffers {
    UInt32 theSize = SizeOf32(AudioBufferList) - SizeOf32(AudioBuffer);
    theSize += inNumberBuffers * SizeOf32(AudioBuffer);
    return theSize;
}

- (void) setupAudioSim {
    [self performSelectorInBackground:@selector(audioSimulator) withObject:nil];
}

#ifdef SWEEP_SIM
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

#else
- (void) audioSimulator {
    float t = 0;
    float frequency1 = 2000;
    float frequency2 = 1500;
    int bufferLength = 1024;
    int sampleRate = 44100;
    int gain1 = 500;
    int gain2 = 1000;
    float bufferDuration = (float)bufferLength / sampleRate;
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
}
#endif
- (void) emitAudioBuffer: (void *)buffer size:(int)size {
    [self.oscilloscopeView setData:buffer size:size];
    [self.spectrumView setData:buffer size:size];

}

@end




static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    ViewController *input = (__bridge ViewController*)inRefCon;
    
    AudioBuffer buffer;
    buffer.mDataByteSize = sizeof(SInt16)*inNumberFrames;
    buffer.mNumberChannels = 1;
    buffer.mData = malloc(sizeof(SInt16)*inNumberFrames); //
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status;
    
    status = AudioUnitRender([input audioUnit],
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    
    if (status != noErr) {
        NSLog(@"Error in AudioUnitRender: %d", status);
        return noErr;
    }
    //NSLog(@"inNoFL %d, inBNL %d", inNumberFrames, inBusNumber);
    [input emitAudioBuffer:bufferList.mBuffers[0].mData size:bufferList.mBuffers[0].mDataByteSize];
    
    return noErr;
}

NSString *NSStringFromOSStatus(OSStatus errCode)
{
    if (errCode == noErr)
        return @"noErr";
    char message[5] = {0};
    *(UInt32*) message = CFSwapInt32HostToBig(errCode);
    return [NSString stringWithCString:message encoding:NSASCIIStringEncoding];
}
