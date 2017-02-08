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
        bufferSize = 2048;
        buffer = malloc(bufferSize);
        _sampleRate = sampleRate;
        
        NSMutableArray * tmpFrequencies = [NSMutableArray array];
        /*
        for (int i = 20; i < 100; i += 10) {
            [tmpFrequencies addObject:@(i)];
        }
        for (int i = 100; i < 1000; i += 50) {
            [tmpFrequencies addObject:@(i)];
        }
        for (int i = 1000; i < 5000; i += 100) {
            [tmpFrequencies addObject:@(i)];
        }
        for (int i = 5000; i < 20000; i += 1000) {
            [tmpFrequencies addObject:@(i)];
        }*/
        for (int i = 20; i < 20000; i += 20) {
            [tmpFrequencies addObject:@(i)];
        }
        frequencies = [NSArray arrayWithArray:tmpFrequencies];
        
        bufferLock = [[NSLock alloc] init];
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

/// outData will be alloc'ed but you have to free it
/*
- (NSArray *) computeOverData:(int16_t *)data length:(long)sampleSize {
    double tmp;
    
    /// First - apply windowing (Hanning)
    for (int i = 0; i < sampleSize; i++) {
        double multiplier = 0.5 * (1 - cos(2*M_PI*i/(sampleSize-1)));
        data[i] = multiplier * data[i];
    }
    
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:frequencies.count];
    long sampleSizeSq = sampleSize * sampleSize;
    for (int fi = 0; fi < frequencies.count; fi ++) {
        double R = 0;
        double I = 0;
        double k = [frequencies[fi] floatValue] * sampleSize / self.sampleRate;
        double tmpFactor = 2 * M_PI * k / sampleSize;
        for (int sampleIndex = 0; sampleIndex < sampleSize; sampleIndex ++) {
            tmp = tmpFactor * sampleIndex;
            R += data[sampleIndex] * cos(tmp);
            I -= data[sampleIndex] * sin(tmp);
        }
        //tmp = sqrt(R * R + I * I);
        tmp = 10 * log10(4 * (R*R + I*I) / sampleSizeSq);
        [result addObject:@{@"f": frequencies[fi],
                            @"p": @(tmp)
                            }];
    }
    
    return result;
}*/

// Based on Radix-2 algorithm
/* This isn't really working, no idea why
- (NSArray *) computeOverData:(int16_t *)data length:(int)n {
    if (n == 1) {
        return @[];
    }
    
    int levels = -1;
    for (int i = 0; i < 32; i++) {
        if (1 << i == n)
            levels = i;  // Equal to log2(n)
    }
    if (levels == -1) {
        NSLog (@"Length is not a power of 2");
        return @[];
    }
    
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:n];
    NSMutableArray * cosTable = [NSMutableArray arrayWithCapacity:n / 2];
    NSMutableArray * sinTable = [NSMutableArray arrayWithCapacity:n / 2];
    for (int i = 0; i < n/2; i ++) {
        cosTable[i] = @(cos(2 * M_PI * i / n));
        sinTable[i] = @(sin(2 * M_PI * i / n));
    }
    
    // prep in-out arrays
    double * real = malloc(sizeof(double) * n);
    double * imag = malloc(sizeof(double) * n);
    for (int i = 0; i < n; i ++) {
        real[i] = data[i];
        imag[i] = 0;
    }
    
    // Bit-reversed addressing permutation
    for (int i = 0; i < n; i++) {
        int j = [self reverse:i bits:levels];
        if (j > i) {
            int16_t temp = data[i];
            data[i] = data[j];
            data[j] = temp;
            / temp = imag[i];
            imag[i] = imag[j];
            imag[j] = temp; /
        }
    }
    
    // Cooley-Tukey decimation-in-time radix-2 FFT
    for (int size = 2; size <= n; size *= 2) {
        int halfsize = size / 2;
        int tablestep = n / size;
        for (int i = 0; i < n; i += size) {
            for (int j = i, k = 0; j < i + halfsize; j++, k += tablestep) {
                double tpre =  real[j+halfsize] * [cosTable[k] doubleValue] + imag[j+halfsize] * [sinTable[k] doubleValue];
                double tpim = -real[j+halfsize] * [sinTable[k] doubleValue] + imag[j+halfsize] * [cosTable[k] doubleValue];
                real[j + halfsize] = real[j] - tpre;
                imag[j + halfsize] = imag[j] - tpim;
                real[j] += tpre;
                imag[j] += tpim;
            }
        }
    }
    
    double tmp;
    double sampleSizeSq = n * n;
    double freqFactor = (double)self.sampleRate / n;
    for (int i = 0; i < n; i += 10) {
        tmp = 10 * log10(4 * (real[i] * real[i] + imag[i] * imag[i]) / sampleSizeSq);
        [result addObject:@{@"f": @(i * freqFactor),
                            @"p": @(tmp)
                            }];
    }
    
    free(real);
    free(imag);
    
    return result;
}

// Returns the integer whose value is the reverse of the lowest 'bits' bits of the integer 'x'.
- (int) reverse:(int)x bits:(int) bits {
    int y = 0;
    for (int i = 0; i < bits; i++) {
        y = (y << 1) | (x & 1);
        x >>= 1;
    }
    return y;
}

 */

- (NSArray *) computeOverData:(int16_t *)data length:(int)n {
    // Hamming window? Or better to use Hann? Blkman?
    float * hammingWindow = (float *) malloc(sizeof(float) * n);
    vDSP_blkman_window(hammingWindow, n, 0);
    float * dataFloat = malloc(sizeof(float) * n);
    for (int i = 0; i < n; i ++) {
        dataFloat[i] = data[i];
    }
    vDSP_vmul(dataFloat, 1, hammingWindow, 1, dataFloat, 1, n);
    
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
    
    vDSP_DFT_Setup setup = vDSP_DFT_zop_CreateSetup(NULL, n, vDSP_DFT_FORWARD);
    
    vDSP_DFT_Execute(setup,
                     inputSplit.realp, inputSplit.imagp,
                     outputSplit.realp, outputSplit.imagp);
    
    vDSP_ztoc(&outputSplit, 1, buf, 2, n);
    
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:n];
    
    // Perhaps use vDSP_vdbcon instead?
    double tmp;
    int sampleSizeSq = n * n;
    double freqFactor = (double)self.sampleRate / n;
    for (int i = 0; i < n; i ++) {
        tmp = 10 * log10(4 * (buf[i].real * buf[i].real + buf[i].imag * buf[i].imag) / sampleSizeSq);
        [result addObject:@{@"f": @(i * freqFactor),
                            @"p": @(tmp)
                            }];
    }
    
    free (buf);
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
