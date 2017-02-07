//
//  AAOscilloscopeView.h
//  AudioAnalyser
//
//  Created by Mariana on 2/4/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AAOscilloscopeView : UIView {
    void * data;
    size_t dataSize;
    size_t dataMaxSize;
}

@property (nonatomic) int bytesPerSample; // This is not used - it is always 2 for the moment!

@property (nonatomic, retain) CADisplayLink * drawDisplayLink;

- (void) setData:(const void *)newData size:(size_t)length;

@end
