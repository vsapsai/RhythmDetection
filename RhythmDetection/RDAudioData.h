//
//  RDAudioData.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/2/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface RDAudioData : NSObject
// data contains buffer of AudioSampleType.
- (id)initWithData:(NSData *)data;

@property (readonly, nonatomic) NSUInteger length;
@property (readonly, nonatomic) AudioSampleType minValue;
@property (readonly, nonatomic) AudioSampleType maxValue;

- (AudioSampleType)valueAtIndex:(NSUInteger)index;
@end
