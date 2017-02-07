//
//  AAOscilloscopeView.m
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "AAOscilloscopeView.h"

@implementation AAOscilloscopeView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        dataMaxSize = 0;
        dataSize = 0;
    }
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (!self.drawDisplayLink) {
        self.drawDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(setNeedsDisplay)];
        [self.drawDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)drawRect:(CGRect)rect {
    @synchronized (self) {
        if (dataSize == 0) {
            return;
        }
        //8NSLog(@"Draw");
        self.bytesPerSample = 2;
        CGContextRef context = UIGraphicsGetCurrentContext();
        //CGContextClearRect(context, self.bounds);
        [[UIColor blackColor] setFill];
        CGContextFillRect(context, self.bounds);
        
        int numberOfSamples = MIN(100, floor(dataSize / self.bytesPerSample));
        float x = 0, y = 0;
        int16_t currentReading;
        int16_t maxReading = 32768; // pow(2, self.bytesPerSample * 8) / 2;
        float xFactor = self.bounds.size.width / numberOfSamples;
        float yFactor = self.bounds.size.height / maxReading;
        
        CGContextBeginPath(context);
        for (int i = 0; i < numberOfSamples; i ++) {
            /*currentReading = 0;
            memcpy(&currentReading, data + i * self.bytesPerSample, self.bytesPerSample);
            */
            currentReading = ((int16_t *)data)[i];
            x = i * xFactor;
            y = self.bounds.size.height/2 - yFactor * currentReading;
            if (i == 0) {
                CGContextMoveToPoint(context, x, y);
            } else {
                CGContextAddLineToPoint(context, x, y);
            }
        }
        
        [[UIColor redColor] setStroke];
        CGContextSetLineWidth(context, 1);
        CGContextStrokePath(context);
    }
}

- (void)setData:(const void *)newData size:(size_t)length {
    @synchronized (self) {
        if (length > dataMaxSize) {
            free(data);
            data = malloc(length);
            dataMaxSize = length;
        }
        memcpy(data, newData, length);
        dataSize = length;
    }
    //[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
}

@end
