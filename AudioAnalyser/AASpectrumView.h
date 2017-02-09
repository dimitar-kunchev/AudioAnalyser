//
//  AASpectrumView.h
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AAAudioManager.h"
#import "AADFT.h"

@interface AASpectrumView : UIView <AAInputReaderDelegate> {
    AADFT * fft;
    BOOL endComputingThread;
    NSArray * fftComputedData;
    
    NSArray * frequencyLines;
}


@end
