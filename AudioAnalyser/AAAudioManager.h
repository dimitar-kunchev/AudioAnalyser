//
//  AAAudioManager.h
//  AudioAnalyser
//
//  Created by Mariana on 2/9/17.
//  Copyright © 2017 DimitarKunchev. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AASignalGenerator.h"
#import "AAInputReader.h"

@interface AAAudioManager : NSObject

@property (nonatomic) BOOL inputEnabled;
@property (nonatomic) BOOL outputEnabled;
@property (nonatomic) BOOL useSimulatedInput;

@property (nonatomic, readonly) AAInputReader * inputReader;
@property (nonatomic, readonly) AASignalGenerator * signalGenerator;

+ (instancetype) manager;

@end
