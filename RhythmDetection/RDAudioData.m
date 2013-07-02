//
//  RDAudioData.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/2/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAudioData.h"

static const NSUInteger kSampleSize = sizeof(AudioSampleType);

@interface RDAudioData()
@property (strong, nonatomic) NSData *data;
@property (readwrite, nonatomic) AudioSampleType minValue;
@property (readwrite, nonatomic) AudioSampleType maxValue;
@end

@implementation RDAudioData

- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (nil != self)
    {
        NSAssert(([data length] % kSampleSize) == 0, @"data isn't buffer of AudioSampleType");
        self.data = [data copy];
        [self computeValueProperties];
    }
    return self;
}

- (const AudioSampleType *)rawData
{
    return (const AudioSampleType *)[self.data bytes];
}

- (void)computeValueProperties
{
    if ([self.data length] > 0)
    {
        const AudioSampleType *samples = [self rawData];
        AudioSampleType minSample = samples[0], maxSample = samples[0];
        for (NSUInteger i = 0; i < self.length; i++)
        {
            const AudioSampleType sample = samples[i];
            if (sample < minSample)
            {
                minSample = sample;
            }
            if (sample > maxSample)
            {
                maxSample = sample;
            }
        }
        self.minValue = minSample;
        self.maxValue = maxSample;
    }
}

- (NSUInteger)length
{
    return ([self.data length] / kSampleSize);
}

- (AudioSampleType)minValue
{
    NSAssert([self.data length] > 0, @"Empty audio data has no minValue");
    return _minValue;
}

- (AudioSampleType)maxValue
{
    NSAssert([self.data length] > 0, @"Empty audio data has no maxValue");
    return _maxValue;
}

- (AudioSampleType)valueAtIndex:(NSUInteger)index
{
    NSParameterAssert(index < self.length);
    const AudioSampleType *samples = [self rawData];
    return samples[index];
}

@end
