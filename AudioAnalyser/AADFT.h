//
//  AADFT.h
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AADFT : NSObject {
    void * buffer;
    long bufferSize;
    NSArray * frequencies;
    
    NSLock * bufferLock;
}

- (id) initWithSampleRate:(int)sampleRate;

@property (nonatomic, readonly) int sampleRate;

- (void) appendData:(const void *)data length:(int)length;

// - (void) computeOverData:(uint16_t *)data length:(long)sampleSize out:(double **)outData outLength:(int *)outDataLength;

- (NSArray *) compute;

@end
