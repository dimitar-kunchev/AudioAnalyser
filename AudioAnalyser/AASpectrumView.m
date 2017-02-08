//
//  AASpectrumView.m
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "AASpectrumView.h"

@implementation AASpectrumView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        fft = [[AADFT alloc] initWithSampleRate:44100];
        
        endComputingThread = NO;
        
        [self performSelectorInBackground:@selector(computingLoop) withObject:NULL];
    }
    return self;
}

- (void) computingLoop {
    while (!endComputingThread) {
        @autoreleasepool {
            //[NSThread sleepForTimeInterval:0.02];
            NSArray * tmp = [fft compute];
            if (tmp != nil) {
                @synchronized (self) {
                    fftComputedData = [tmp copy];
                }
                [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:NULL waitUntilDone:YES];
            }
        }
    }
}

- (void)dealloc {
    endComputingThread = YES;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] setFill];
    CGContextFillRect(context, self.bounds);
    
    NSArray * tmp;
    @synchronized (self) {
        tmp = [NSArray arrayWithArray:fftComputedData];
    }
    
    if (tmp) {
        
        CGContextBeginPath(context);
        
        long bands = tmp.count;
        
        float yFactor = (self.bounds.size.height-5) / 96; // assume 96dB max
        //float yFS = pow(2, 15);
        for (int i = 0; i < tmp.count; i ++) {
            float xs = (i == 0 ? 0 : self.bounds.size.width * log10f(i) / log10f(bands));
            //float ys = 20 * log10([tmp[i][@"p"] doubleValue] / yFS) * yFactor;
            float ys = [tmp[i][@"p"] doubleValue] * yFactor;
            if (i == 0) {
                CGContextMoveToPoint(context, xs, self.bounds.size.height-ys);
            } else {
                CGContextAddLineToPoint(context, xs, self.bounds.size.height-ys);
            }
        }
        [[UIColor blueColor] setStroke];
        CGContextSetLineWidth(context, 1);
        CGContextStrokePath(context);
    }
}


- (void) setData:(const void *)newData size:(size_t)length {
    [fft appendData:newData length:(int)length];
    
    
}

@end
