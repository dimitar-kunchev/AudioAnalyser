//
//  AASignalGenerator.h
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AudioToolbox/AudioToolbox.h>

#import "CommonHelpers.h"

@interface AASignalGenerator : NSObject {
    AudioComponentInstance _audioUnitOutput;

}

@property (nonatomic) BOOL enabled;

@property (nonatomic) double amplitude;
@property (nonatomic) double frequency;


@end
