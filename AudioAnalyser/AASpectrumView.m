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
            [NSThread sleepForTimeInterval:0.02];
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
        [[UIColor blueColor] setFill];
        
        long bands = tmp.count;
        float bandWidth = self.bounds.size.width / bands;
        float yFactor = (self.bounds.size.height-5);
        float yFS = pow(2, 16);
        for (int i = 0; i < tmp.count; i ++) {
            float xs = i * bandWidth;
            float ys;
            
            ys = log10f([tmp[i][@"p"] floatValue] / yFS) * yFactor;
            if (ys > 1) {
                CGContextFillRect(context, CGRectMake(xs, self.bounds.size.height-5, bandWidth, -ys));
            }
        }
        
        [[UIColor yellowColor] setFill];
        
        for (int i = 0; i < tmp.count; i ++) {
            float xs = i * bandWidth;
            CGContextFillRect(context, CGRectMake(xs+1, self.bounds.size.height-5, bandWidth-2, 5));
        }
    }
}


- (void) setData:(const void *)newData size:(size_t)length {
    [fft appendData:newData length:(int)length];
    
    
}

@end
