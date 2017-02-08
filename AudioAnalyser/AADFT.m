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
        res = [self computeOverData:tmpBuffer length:tmpBufferSize/2];
    }
    free (tmpBuffer);

    return res;
}

@end
