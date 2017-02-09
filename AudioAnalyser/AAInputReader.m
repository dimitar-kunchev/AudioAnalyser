//
//  AAInputReader.m
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "AAInputReader.h"


static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData);


@interface AAInputReader ()

@property (nonatomic) AudioComponentInstance audioUnit;
@property (nonatomic) double sampleRate;

@end


@implementation AAInputReader

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = NO;
        _simulateInput = NO;
        _simulatedFrequency = 500;
        _simulatedAmplitude = 0.5;
        _sampleRate = 96000;
        [self setupAudioUnit];
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    if (enabled != _enabled) {
        _enabled = enabled;
        if (enabled) {
            if (self.simulateInput) {
                [self startSimulatedInput];
            } else {
                [self startMicrophoneInput];
            }
        } else {
            if (self.simulateInput) {
                [self stopSimulatedInput];
            } else {
                [self stopMicrophoneInput];
            }
        }
    }
}

- (void) setupAudioUnit {
    OSStatus status;
    
    AudioComponentDescription defaultInputDescription;
    defaultInputDescription.componentType = kAudioUnitType_Output;
    defaultInputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultInputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultInputDescription.componentFlags = 0;
    defaultInputDescription.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &defaultInputDescription);
    status = AudioComponentInstanceNew(inputComponent, &_audioUnit);
    
    // Enable recording
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
    // Disable playback
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
    audioFormat.mSampleRate         = self.sampleRate;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagsNativeFloatPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 32;
    audioFormat.mBytesPerPacket     = 4;
    audioFormat.mBytesPerFrame      = 4;
    
    // Apply format
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBusNumber,
                                  &audioFormat,
                                  sizeof(audioFormat));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (format output)");
        return;
    }
    
    // Set input callback
    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc = recordingCallback;
    inputCallbackStruct.inputProcRefCon = (__bridge void*)self;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Input,
                                  kInputBusNumber,
                                  &inputCallbackStruct,
                                  sizeof(inputCallbackStruct));
    if (status != noErr) {
        NSLog(@"Error in AudioUnitSetProperty (record callback): %d", (int)status);
        return;
    }
    
    status = AudioUnitInitialize(_audioUnit);
    if (status != noErr) {
        NSLog(@"Error in AudioUnitInitialize: %@", NSStringFromOSStatus(status));
        return;
    }
    
    NSLog(@"%@ ready", NSStringFromClass(self.class));
}

- (void) startMicrophoneInput {
    OSStatus status;
    
    status = AudioOutputUnitStart(_audioUnit);
    if (status != noErr) {
        NSLog(@"Error in AudioUnitStart: %@", NSStringFromOSStatus(status));
        return;
    } else {
        NSLog(@"%@ started", NSStringFromClass(self.class));
    }
}

- (void) stopMicrophoneInput {
    OSStatus status;
    status = AudioOutputUnitStop(_audioUnit);
    if (status != noErr) {
        NSLog(@"Error in AudioOutputUnitStop: %@", NSStringFromOSStatus(status));
        // do not return - let the method proceed
    }
    NSLog(@"%@ stopped", NSStringFromClass(self.class));
}

- (void) emitAudioBuffer: (void *)buffer size:(int)size {
    /// Distribute to listeners
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputGotAudioBuffer:size:)]) {
        [self.delegate inputGotAudioBuffer:buffer size:size];
    }
}

- (void)setSimulateInput:(BOOL)simulateInput {
    if (_simulateInput != simulateInput) {
        _simulateInput = simulateInput;
        if (self.enabled) {
            if (_simulateInput) {
                [self stopMicrophoneInput];
                [self startSimulatedInput];
            } else {
                [self stopSimulatedInput];
                [self startMicrophoneInput];
            }
        }
    }
}

- (void) startSimulatedInput {
    simulatedInputThread = [[NSThread alloc] initWithTarget:self selector:@selector(simulatedInputGenerator) object:nil];
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    [simulatedInputThread setName:[appID stringByAppendingString:@".simulated-input"]];
    [simulatedInputThread start];
    NSLog(@"Started simulated input");
}

- (void) stopSimulatedInput {
    [simulatedInputThread cancel];
    simulatedInputThread = nil;
    NSLog(@"Stoppped simulated input");
}

- (void) simulatedInputGenerator {
    int bufferLength = 2048;
    float bufferDuration = (float)bufferLength / self.sampleRate;
    Float32 *buffer = malloc(sizeof(Float32) * bufferLength);
    float t = 0;
    while (self.simulateInput || [[NSThread currentThread] isCancelled]) {
        @autoreleasepool {
            float t_inc = 2 * M_PI * self.simulatedFrequency / self.sampleRate;
            for (int i = 0; i < bufferLength; i ++) {
                buffer[i] = sin(t) * self.simulatedAmplitude;
                t += t_inc;
                if (t > 2*M_PI) {
                    t -= 2*M_PI;
                }
            }
            
            [self emitAudioBuffer:buffer size:sizeof(Float32) * bufferLength];
            // technically this is incorrect, because it does not account for the duration of the buffer generation, but there aren't any obvious gaps and this method is intended for debugging only so...
            [NSThread sleepForTimeInterval:bufferDuration];
        }
    }
    free (buffer);
}

@end


/// ----


static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    //NSLog(@"Rec callback bus %d", inBusNumber);
    AAInputReader *reference = (__bridge AAInputReader*)inRefCon;
    
    AudioBuffer buffer;
    buffer.mDataByteSize = sizeof(Float32)*inNumberFrames;
    buffer.mNumberChannels = 1;
    buffer.mData = malloc(sizeof(Float32)*inNumberFrames); //
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status;
    
    status = AudioUnitRender([reference audioUnit],
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    
    if (status != noErr) {
        NSLog(@"Error in AudioUnitRender: %d", (int)status);
        return noErr;
    }
    //NSLog(@"inNoFL %d, inBNL %d", inNumberFrames, inBusNumber);
    [reference emitAudioBuffer:bufferList.mBuffers[0].mData size:bufferList.mBuffers[0].mDataByteSize];
    
    free(buffer.mData);
    
    return noErr;
}
