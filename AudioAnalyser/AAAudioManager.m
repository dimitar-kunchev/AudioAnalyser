//
//  AAAudioManager.m
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import "AAAudioManager.h"

@implementation AAAudioManager

+ (instancetype) manager {
    static AAAudioManager * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AAAudioManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _inputReader = [[AAInputReader alloc] init];
        _signalGenerator = [[AASignalGenerator alloc] init];
    }
    return self;
}

- (void)dealloc {
    self.inputReader.enabled = NO;
    self.signalGenerator.enabled = NO;
}

# pragma mark -

- (void)setInputEnabled:(BOOL)enabled {
    _inputEnabled = enabled;
    self.inputReader.enabled = enabled;
}

- (void)setOutputEnabled:(BOOL)enabled {
    _outputEnabled = enabled;
    self.signalGenerator.enabled = enabled;
}

- (void)setUseSimulatedInput:(BOOL)useSimulatedInput {
    [self.inputReader setSimulateInput:useSimulatedInput];
}

- (BOOL)useSimulatedInput {
    return [self.inputReader simulateInput];
}

@end
