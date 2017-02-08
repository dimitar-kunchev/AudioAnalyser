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
        
        frequencyLines = [NSArray arrayWithObjects:@(10), @(20), @(50), @(100), @(200), @(500), @(1000), @(2000), @(5000), @(10000), @(20000), nil];
        
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
        
        //long bands = tmp.count;
        
        float yFactor = (self.bounds.size.height-5) / 130; // assume 50dB max
        float yFS = pow(2, 15);
        float xFactor = self.bounds.size.width / log2(20000/5);
        
        // first draw a few vertical lines to mark some frequencies
        [[UIColor grayColor] setFill];
        for (NSNumber * fl in frequencyLines) {
            float x = xFactor * log2(fl.floatValue/5);
            CGContextFillRect(context, CGRectMake(x-0.5, 0, 1, self.bounds.size.height));
        }
        
        CGContextBeginPath(context);
        for (int i = 0; i < tmp.count; i ++) {
            float xs = ([tmp[i][@"f"] doubleValue] == 0 ? 0 : xFactor * log2([tmp[i][@"f"] doubleValue]/5));
            float p = [tmp[i][@"p"] doubleValue];
            float dbLevel = (p == 0 ? -500 : 20 * log10(p));
            float ys = dbLevel * yFactor;
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
