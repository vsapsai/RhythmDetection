//
//  RDAudioPlayback.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface RDAudioPlayback : NSObject
{
@private
    AUGraph _graph;
	AudioUnit _outputUnit;
}
- (id)initWithURL:(NSURL *)url;

- (void)start;
- (void)stop;

- (float)currentProgress;
@end
