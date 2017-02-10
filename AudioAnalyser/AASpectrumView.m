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
        minDisplayValue = -120;
        maxDisplayValue = 120;
        fft = [[AADFT alloc] initWithSampleRate:96000 bitRate:sizeof(Float32)];
        
        endComputingThread = NO;
        
        frequencyLines = [NSArray arrayWithObjects:@(20), @(50), @(100), @(200), @(500), @(1000), @(2000), @(5000), @(10000), @(20000), nil];
        
        [self performSelectorInBackground:@selector(computingLoop) withObject:NULL];
        
        [self setUserInteractionEnabled:YES];
    }
    return self;
}

- (void) computingLoop {
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    [[NSThread currentThread] setName:[appID stringByAppendingString:@".spectrum"]];
    while (!endComputingThread) {
        @autoreleasepool {
            [NSThread sleepForTimeInterval:0.02];
            NSDictionary * tmp = [fft compute];
            if (tmp != nil) {
                @synchronized (self) {
                    fftComputedData = [tmp[@"data"] copy];
                    /*
                    if (minDisplayValue > [tmp[@"min"] floatValue]) {
                        minDisplayValue = [tmp[@"min"] floatValue];
                        minDisplayValue = floorf(minDisplayValue / 10.0) * 10.0;
                        NSLog(@"Adjust minDB Level: %.2f", minDisplayValue);
                    }
                    if (maxDisplayValue < [tmp[@"max"] floatValue]) {
                        maxDisplayValue = [tmp[@"max"] floatValue];
                        maxDisplayValue = floorf(maxDisplayValue / 10.0) * 10.0;
                        NSLog(@"Adjust maxDB Level: %.2f", maxDisplayValue);
                    }*/
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
        
        float yFactor = (self.bounds.size.height-5) / (maxDisplayValue - minDisplayValue); // pixels per dB
        // float yFS = pow(2, 15);
        float minFreqLog = log2(20/5);
        float xFactor = self.bounds.size.width / (log2(20000/5) - minFreqLog); // max-min freq
        
        // first draw a few vertical lines to mark some frequencies
        [[UIColor grayColor] setFill];
        for (NSNumber * fl in frequencyLines) {
            float x = xFactor * (log2(fl.floatValue/5) - minFreqLog);
            CGContextFillRect(context, CGRectMake(x-0.5, 0, 1, self.bounds.size.height));
        }
        
        // draw horizontal lines every 10dB
        float drawDBLineEvery = ((maxDisplayValue - minDisplayValue) / 10.0 > 20 ? 20 : 10);
        for (int i = round(minDisplayValue); i < maxDisplayValue; i += drawDBLineEvery) {
            float y = yFactor * (maxDisplayValue - i);
            if (i < 1 && i > -1) {
                // Mark 0dB a bit better
                CGContextFillRect(context, CGRectMake(0, y-1.5, self.bounds.size.width, 3));
            } else {
                CGContextFillRect(context, CGRectMake(0, y-0.5, self.bounds.size.width, 1));
            }
        }
        
        // draw the selected output frequency
        if ([[AAAudioManager manager] outputEnabled]) {
            float focusedFrequency = [[[AAAudioManager manager] signalGenerator] frequency];
            if (focusedFrequency > 0) {
                float xs = xFactor * (log2(focusedFrequency/5) - minFreqLog);
                [[UIColor blueColor] setFill];
                CGContextFillRect(context, CGRectMake(xs-1.5, 0, 3, self.bounds.size.height));
            }
        }
        
        // draw the spectre
        // This is not as easy as it sounds, because just throwing the points in a CGPath is too intensive on the CPU.
        // Instead we do it for the first few points (below 200Hz). After that we start combining and taking the maximum value
        CGContextBeginPath(context);
        int i = 1; // skip the 0Hz entry. If you ever reenable it make sure to avoind log(0)
        int combinePoints = 1;
        float frequency, xs, power, ys;
        while (i < tmp.count) {
            frequency = [tmp[i][@"f"] doubleValue];
            
            if (frequency > 200) {
                combinePoints = 5;
            }
            
            power = [tmp[i][@"p"] doubleValue];
            if (combinePoints > 1) {
                for (int j = i; j < i + combinePoints && j < tmp.count; j ++) {
                    power = MAX(power, [tmp[j][@"p"] doubleValue]);
                }
                // Take the middle frequency of the range
                frequency = [tmp[i + (int)floor(combinePoints/2.0)][@"f"] doubleValue];
            }
            
            //xs = (frequency == 0 ? 0 : xFactor * (log2(frequency/5) - minFreqLog));
            xs = xFactor * (log2(frequency/5) - minFreqLog);
            ys = (maxDisplayValue - power) * yFactor;
            if (isinf(power) || isnan(ys) || isinf(ys)) ys = -10000;
            if (i == 1) {
                CGContextMoveToPoint(context, xs, ys);
            } else {
                CGContextAddLineToPoint(context, xs, ys);
            }
            i+= combinePoints;
        }
        [[UIColor redColor] setStroke];
        CGContextSetLineWidth(context, 1);
        CGContextStrokePath(context);
    }
}


- (void) inputGotAudioBuffer: (void *)buffer size:(int)size {
    [fft appendData:buffer length:(int)size];
}

#pragma mark - User interaction

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self selectFrequencyFromTouch:[touches anyObject]];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self selectFrequencyFromTouch:[touches anyObject]];
}

- (void) selectFrequencyFromTouch:(UITouch *)touch {
    CGPoint location = [touch locationInView:self];
    float x = location.x;
    // convert to frequency
    float minFreqLog = log2(20/5);
    float xFactor = self.bounds.size.width / (log2(20000/5) - minFreqLog);
    // x = xFactor * (log2(frequency/5) - minFreqLog)
    float frequency = pow(2, (x / xFactor) + minFreqLog)*5;
    /// round the frequency to one of the FFT bins - makes the interface a bit cooler
    /// The trick is to use the output of the FFT to snap to one of its frequencies
    if (fftComputedData.count > 0) {
        float minFreq = [fftComputedData[0][@"f"] floatValue];
        float maxFreq = [fftComputedData.lastObject[@"f"] floatValue];
        float step = (maxFreq - minFreq) / (fftComputedData.count - 1);
        frequency = roundf(frequency / step) * step;
    }
    [[[AAAudioManager manager] signalGenerator] setFrequency:frequency];
}

@end
