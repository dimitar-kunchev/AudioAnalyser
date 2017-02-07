//
//  AASpectrumView.h
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AADFT.h"

@interface AASpectrumView : UIView {
    AADFT * fft;
    BOOL endComputingThread;
    NSArray * fftComputedData;
}

- (void) setData:(const void *)newData size:(size_t)length;

@end
