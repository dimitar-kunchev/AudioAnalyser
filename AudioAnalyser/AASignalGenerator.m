//
//  AASignalGenerator.m
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "AASignalGenerator.h"


OSStatus playbackCallback(void *inRefCon,
                          AudioUnitRenderActionFlags 	*ioActionFlags,
                          const AudioTimeStamp 		*inTimeStamp,
                          UInt32 						inBusNumber,
                          UInt32 						inNumberFrames,
                          AudioBufferList 			*ioData);

@interface AASignalGenerator ()

@property (nonatomic) double theta;
@property (nonatomic) double amplitude;
@property (nonatomic) double frequency;
@property (nonatomic) double sampleRate;
@property (nonatomic) double bitRate;

@end


@implementation AASignalGenerator

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = NO;
        _frequency = 400;
        _amplitude = 0.5;
        _theta = 0;
        _sampleRate = 96000;
        _bitRate = 32;
        [self setupAudioUnit];
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    if (enabled != _enabled) {
        _enabled = enabled;
        if (enabled) {
            [self start];
        } else {
            [self stop];
        }
    }
}

- (void)dealloc {
    AudioComponentInstanceDispose(_audioUnitOutput);
    _audioUnitOutput = nil;
}

- (void) setupAudioUnit {
    NSLog(@"Attempting to setup output unit");
    if (_audioUnitOutput) {
        NSLog(@"Unit already initialized");
        return;
    }
    OSStatus status;
    
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    AudioComponent outputComponent = AudioComponentFindNext(NULL, &defaultOutputDescription);
    status = AudioComponentInstanceNew(outputComponent, &_audioUnitOutput);
    
    // Disable recording
    UInt32 flag = 0;
    status = AudioUnitSetProperty(_audioUnitOutput,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBusNumber,
                                  &flag,
                                  sizeof(flag));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (enable recording)");
        return;
    }
    
    // Enable playback
    flag = 1;
    status = AudioUnitSetProperty(_audioUnitOutput,
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
    audioFormat.mSampleRate         = self.sampleRate;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagsNativeFloatPacked; /// | kAudioFormatFlagIsNonInterleaved
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 2;
    audioFormat.mBitsPerChannel     = self.bitRate;
    audioFormat.mBytesPerPacket     = (self.bitRate / 8) * 2;
    audioFormat.mBytesPerFrame      = audioFormat.mBytesPerPacket;
    // Apply format
    status = AudioUnitSetProperty(_audioUnitOutput,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBusNumber,
                                  &audioFormat,
                                  sizeof(audioFormat));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (format input)");
        return;
    }
    
    
    // Set render callback
    AURenderCallbackStruct playbackCallbackStruct;
    playbackCallbackStruct.inputProc = playbackCallback;
    playbackCallbackStruct.inputProcRefCon = (__bridge void*)self;
    status = AudioUnitSetProperty(_audioUnitOutput,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBusNumber,
                                  &playbackCallbackStruct,
                                  sizeof(playbackCallbackStruct));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (render callback): %@", NSStringFromOSStatus(status));
        return;
    }
    
    status = AudioUnitInitialize(_audioUnitOutput);
    if (status != noErr) {
        NSLog(@"Error in AudioUnitInitialize: %@", NSStringFromOSStatus(status));
        return;
    }
    
    NSLog(@"%@ ready", NSStringFromClass(self.class));
    
}

- (void) start {
    OSStatus status;
    status = AudioOutputUnitStart(_audioUnitOutput);
    if (status != noErr) {
        NSLog(@"Error in AudioUnitStart: %@", NSStringFromOSStatus(status));
        return;
    } else {
        NSLog(@"%@ started", NSStringFromClass(self.class));
    }
}

- (void) stop {
    OSStatus status;
    status = AudioOutputUnitStop(_audioUnitOutput);
    if (status != noErr) {
        NSLog(@"Error in AudioOutputUnitStop: %@", NSStringFromOSStatus(status));
        // do not return - let the method proceed
    }
    NSLog(@"%@ stopped", NSStringFromClass(self.class));
}

@end


//// ------


OSStatus playbackCallback(void *inRefCon,
                          AudioUnitRenderActionFlags 	*ioActionFlags,
                          const AudioTimeStamp 		*inTimeStamp,
                          UInt32 						inBusNumber,
                          UInt32 						inNumberFrames,
                          AudioBufferList 			*ioData) {
    // Get the tone parameters out of host instance
    AASignalGenerator *reference = (__bridge AASignalGenerator *)inRefCon;
    double theta = reference.theta;
    double theta_increment = 2.0 * M_PI * reference.frequency / reference.sampleRate;
    double amplitude = reference.amplitude;
    
    Float32 *buffer = (Float32 *)ioData->mBuffers[0].mData;
    int numberOfChannels = ioData->mBuffers[0].mNumberChannels;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames*numberOfChannels; frame += numberOfChannels) {
        buffer[frame] = sin(theta) * amplitude;
        if (numberOfChannels > 1) {
            buffer[frame+1] = buffer[frame];
        }
        
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    
    // Store the theta back in the view controller
    reference.theta = theta;
    
    return noErr;
}
