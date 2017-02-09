//
//  ViewController.h
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "AASpectrumView.h"

#import "AAAudioManager.h"

@interface ViewController : UIViewController <AVCaptureAudioDataOutputSampleBufferDelegate> {
}

@property (nonatomic, retain) IBOutlet AASpectrumView * spectrumView;

@end

