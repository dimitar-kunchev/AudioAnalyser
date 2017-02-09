//
//  AAInputReader.h
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CommonHelpers.h"
#import "AADFT.h"

@protocol AAInputReaderDelegate;


@interface AAInputReader : NSObject {
    NSThread * simulatedInputThread;
}

@property (nonatomic) BOOL enabled;

@property (nonatomic) BOOL simulateInput;
@property (nonatomic) float simulatedFrequency;
@property (nonatomic) float simulatedAmplitude;

@property (nonatomic, assign) id<AAInputReaderDelegate> delegate;

@end


@protocol AAInputReaderDelegate <NSObject>
@required
- (void) inputGotAudioBuffer: (void *)buffer size:(int)size;

@end
