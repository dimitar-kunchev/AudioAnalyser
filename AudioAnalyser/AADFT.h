//
//  AADFT.h
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

@interface AADFT : NSObject {
    void * buffer;
    long bufferSize;
    NSArray * frequencies;
    
    NSLock * bufferLock;
    
    vDSP_DFT_Setup DFTSetup;
}

- (id) initWithSampleRate:(int)sampleRate bitRate:(int)bitsPerPacket;

@property (nonatomic, readonly) int sampleRate;

- (void) appendData:(const void *)data length:(int)length;

// - (void) computeOverData:(uint16_t *)data length:(long)sampleSize out:(double **)outData outLength:(int *)outDataLength;

- (NSArray *) compute;

@end
