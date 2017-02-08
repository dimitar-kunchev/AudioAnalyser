//
//  AADFT.m
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "AADFT.h"

@implementation AADFT

- (id) initWithSampleRate:(int)sampleRate {
    self = [super init];
    if (self) {
        bufferSize = 2048 * 4;
        buffer = malloc(bufferSize);
        _sampleRate = sampleRate;
        
        NSMutableArray * tmpFrequencies = [NSMutableArray array];
        for (int i = 10; i < 20; i += 2) {
            [tmpFrequencies addObject:@(i)];
        }
        for (int i = 20; i < 20000; i += 20) {
            [tmpFrequencies addObject:@(i)];
        }
        frequencies = [NSArray arrayWithArray:tmpFrequencies];
        
        bufferLock = [[NSLock alloc] init];
        
        DFTSetup = NULL;
    }
    return self;
}

- (void) appendData:(const void *)data length:(int)length {
    if ([bufferLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]) {
        memmove(buffer, buffer + length, bufferSize - length);
        memcpy(buffer + bufferSize - length, data, length);
        [bufferLock unlock];
    }
}

- (void)dealloc {
    free (buffer);
    buffer = NULL;
}

- (NSArray *) computeOverData:(int16_t *)data length:(int)n {
    // Hamming window? Or better to use Hann? Blkman?
    float * windowCoefficients = (float *) malloc(sizeof(float) * n);
    vDSP_hann_window(windowCoefficients, n, 0);
    float * dataFloat = malloc(sizeof(float) * n);
    for (int i = 0; i < n; i ++) {
        dataFloat[i] = data[i];
    }
    vDSP_vmul(dataFloat, 1, windowCoefficients, 1, dataFloat, 1, n);
    free(windowCoefficients);
    
    // prepare input for the DSP
    DSPComplex * buf = malloc(sizeof(DSPComplex) * n);
    for (int i = 0; i < n; i ++) {
        buf[i].real = dataFloat[i];
        buf[i].imag = 0;
    }
    
    // dispose of the temporary float array
    free(dataFloat);
    
    float inputMemory[2*n];
    float outputMemory[2*n];
    // half for real and half for complex
    DSPSplitComplex inputSplit = {inputMemory, inputMemory + n};
    DSPSplitComplex outputSplit = {outputMemory, outputMemory + n};
    
    vDSP_ctoz(buf, 2, &inputSplit, 1, n);
    
    free (buf);
    
    if (DFTSetup == NULL) {
        DFTSetup = vDSP_DFT_zop_CreateSetup(NULL, n, vDSP_DFT_FORWARD);
    }
    
    vDSP_DFT_Execute(DFTSetup,
                     inputSplit.realp, inputSplit.imagp,
                     outputSplit.realp, outputSplit.imagp);

    NSMutableArray * result = [NSMutableArray arrayWithCapacity:n];
    outputSplit.imagp[0] = 0;
    float * spectrum = malloc(sizeof(float) * n);
    vDSP_zvmags(&outputSplit, 1, spectrum, 1, n);
    
    // Add -128db offset to avoid log(0).
    float kZeroOffset = 1.5849e-13;
    vDSP_vsadd(spectrum, 1, &kZeroOffset, spectrum, 1, n);
    
    // Convert power to decibel.
    float kZeroDB = 0.70710678118f; // 1/sqrt(2)
    vDSP_vdbcon(spectrum, 1, &kZeroDB, spectrum, 1, n, 1);
    
    double freqFactor = (double)self.sampleRate / n;
    [result addObject:@{@"f": @(0),
                        @"p": @(-200)
                        }];
    for (int i = 1; i * freqFactor < 20000; i ++) {
        [result addObject:@{@"f": @(i * freqFactor),
                            @"p": @(spectrum[i] - 144)
                            }];
    }
    free(spectrum);
    return result;
}

- (NSArray *) compute {
    long tmpBufferSize = bufferSize;
    int16_t * tmpBuffer = malloc(tmpBufferSize);
    if (tmpBuffer == NULL) {
        return nil;
    }
    memset(tmpBuffer, 0, tmpBufferSize);
    BOOL gotBuffer = NO;
    if ([bufferLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]) {
        memcpy(tmpBuffer, buffer, tmpBufferSize);
        gotBuffer = YES;
        [bufferLock unlock];
    }
    
    NSArray * res = nil;
    if (gotBuffer) {
        res = [self computeOverData:tmpBuffer length:(int)tmpBufferSize/2];
    }
    free (tmpBuffer);

    return res;
}


@end
