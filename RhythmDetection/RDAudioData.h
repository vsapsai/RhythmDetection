//
//  RDAudioData.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/2/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

// RDAudioData is intended to be used for audio signal processing.
@interface RDAudioData : NSObject
// data contains buffer of AudioSampleType.
- (id)initWithData:(NSData *)data;

- (const AudioSampleType *)rawData NS_RETURNS_INNER_POINTER;

@property (readonly, nonatomic) NSUInteger length;
@property (readonly, nonatomic) AudioSampleType minValue;
@property (readonly, nonatomic) AudioSampleType maxValue;

- (AudioSampleType)valueAtIndex:(NSUInteger)index;
@end
