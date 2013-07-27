//
//  RDRepeatedDataGenerator.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDRepeatedDataGenerator.h"

@implementation RDRepeatedDataGenerator

+ (NSData *)generateDataWithPattern:(NSData *)pattern samplingRate:(NSUInteger)samplingRate length:(NSUInteger)length
{
    NSParameterAssert([pattern length] > 0);
    NSAssert([pattern length] % sizeof(float) == 0, @"pattern should be NSData of float");
    NSParameterAssert(samplingRate > 0);
    NSParameterAssert(length > 0);
    NSMutableData *result = [[NSMutableData alloc] initWithLength:(length * sizeof(float))];
    float *resultBuffer = (float *)[result mutableBytes];
    const float *patternBuffer = (const float *)[pattern bytes];
    NSUInteger patternIndex = 0;
    NSUInteger patternLength = ([pattern length] / sizeof(float));
    NSUInteger indexInSample = 0;
    for (NSUInteger i = 0; i < length; i++)
    {
        resultBuffer[i] = patternBuffer[patternIndex];
        indexInSample++;
        if (indexInSample >= samplingRate)
        {
            NSAssert(indexInSample == samplingRate, @"How have you missed the point when variables were equal?");
            indexInSample = 0;
            patternIndex = (patternIndex + 1) % patternLength;
        }
    }
    return [result copy];
}

+ (NSData *)generateDataWithPattern:(NSData *)pattern length:(NSUInteger)length
{
    return [self generateDataWithPattern:pattern samplingRate:1 length:length];
}

@end
