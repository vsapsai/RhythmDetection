//
//  RDRepeatedDataGeneratorTest.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RDRepeatedDataGenerator.h"

@interface RDRepeatedDataGeneratorTest : SenTestCase
@end

#define NS_DATA_FROM_C_ARRAY(cArray) [NSData dataWithBytes:(void *)cArray length:sizeof(cArray)]

@implementation RDRepeatedDataGeneratorTest

- (void)testTrivial
{
    float patternArray[] = {1.0f, 0.0f};
    NSData *pattern = NS_DATA_FROM_C_ARRAY(patternArray);
    NSData *actual = [RDRepeatedDataGenerator generateDataWithPattern:pattern samplingRate:1 length:4];
    float expectedArray[] = {1.0f, 0.0f, 1.0f, 0.0f};
    NSData *expected = NS_DATA_FROM_C_ARRAY(expectedArray);
    STAssertEqualObjects(actual, expected, nil);
}

- (void)testLengthShorterThanPattern
{
    float patternArray[] = {1.0f, 2.0f, 3.0f};
    NSData *pattern = NS_DATA_FROM_C_ARRAY(patternArray);
    NSData *actual = [RDRepeatedDataGenerator generateDataWithPattern:pattern samplingRate:1 length:2];
    float expectedArray[] = {1.0f, 2.0f};
    NSData *expected = NS_DATA_FROM_C_ARRAY(expectedArray);
    STAssertEqualObjects(actual, expected, nil);
}

- (void)testLengthNotDivisibleByPatternLength
{
    float patternArray[] = {1.0f, 0.0f};
    NSData *pattern = NS_DATA_FROM_C_ARRAY(patternArray);
    NSData *actual = [RDRepeatedDataGenerator generateDataWithPattern:pattern samplingRate:1 length:3];
    float expectedArray[] = {1.0f, 0.0f, 1.0f};
    NSData *expected = NS_DATA_FROM_C_ARRAY(expectedArray);
    STAssertEqualObjects(actual, expected, nil);
}

- (void)testSamplingRate
{
    float patternArray[] = {1.0f, 0.0f};
    NSData *pattern = NS_DATA_FROM_C_ARRAY(patternArray);
    NSData *actual = [RDRepeatedDataGenerator generateDataWithPattern:pattern samplingRate:2 length:4];
    float expectedArray[] = {1.0f, 1.0f, 0.0f, 0.0f};
    NSData *expected = NS_DATA_FROM_C_ARRAY(expectedArray);
    STAssertEqualObjects(actual, expected, nil);
}

- (void)testBigSamplingRate
{
    float patternArray[] = {1.0f, 0.0f};
    NSData *pattern = NS_DATA_FROM_C_ARRAY(patternArray);
    NSData *actual = [RDRepeatedDataGenerator generateDataWithPattern:pattern samplingRate:5 length:4];
    float expectedArray[] = {1.0f, 1.0f, 1.0f, 1.0f};
    NSData *expected = NS_DATA_FROM_C_ARRAY(expectedArray);
    STAssertEqualObjects(actual, expected, nil);
}

@end
