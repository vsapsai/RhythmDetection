//
//  RDAudioFile.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/30/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@class RDBufferList;

@interface RDAudioFile : NSObject
- (id)initWithURL:(NSURL *)url;

// Properties.
- (Float64)sampleRate;
- (SInt64)framesCount;
- (NSTimeInterval)duration;

// Caller is responsible for providing buffer list of sufficient size.
- (void)readDataInFormat:(AudioStreamBasicDescription)dataFormat inBufferList:(RDBufferList *)bufferList;
- (NSData *)PCMRepresentation;
@end
