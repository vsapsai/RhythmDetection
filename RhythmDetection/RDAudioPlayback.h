//
//  RDAudioPlayback.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class RDAudioFile;

@interface RDAudioPlayback : NSObject
{
@private
    AUGraph _graph;
	AudioUnit _outputUnit;
}
- (id)initWithAudioFile:(RDAudioFile *)audioFile;

- (void)start;
- (void)stop;

- (float)currentProgress;
// It is not guaranteed that currentProgress will be equal to set progress.
- (void)setCurrentProgress:(float)progress;
@end
