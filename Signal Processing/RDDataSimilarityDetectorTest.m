//
//  RDDataSimilarityDetectorTest.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/27/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RDDataSimilarityDetector.h"
#import "RDRepeatedDataGenerator.h"
#include <stdarg.h>

static const NSUInteger kLength = 32;

@interface RDDataSimilarityDetectorTest : SenTestCase
@property (strong, nonatomic) RDDataSimilarityDetector *similarityDetector;
@end

@implementation RDDataSimilarityDetectorTest

- (void)setUp
{
    self.similarityDetector = [[RDDataSimilarityDetector alloc] initWithLength:kLength];
}

- (void)tearDown
{
    self.similarityDetector = nil;
}

- (void)testBestMatch
{
    NSData *dataPause1 = [self dataWithPattern:2, 1.0, 0.0];
    NSData *dataPause2 = [self dataWithPattern:3, 1.0, 0.0, 0.0];
    NSData *dataPause3 = [self dataWithPattern:4, 1.0, 0.0, 0.0, 0.0];
    float similarity1_1 = [self.similarityDetector similarityMeasureBetweenData:dataPause1 andData:dataPause1];
    float similarity1_2 = [self.similarityDetector similarityMeasureBetweenData:dataPause1 andData:dataPause2];
    float similarity1_3 = [self.similarityDetector similarityMeasureBetweenData:dataPause1 andData:dataPause3];
    STAssertTrue(similarity1_1 > similarity1_2, nil);
    STAssertTrue(similarity1_1 > similarity1_3, nil);
}

- (void)testAmplitudeSkewingResults
{
    NSData *dataPause1 = [self dataWithPattern:2, 1.0, 0.0];
    NSData *dataPause2 = [self dataWithPattern:3, 100.0, 0.0, 0.0];
    float similarity1_1 = [self.similarityDetector similarityMeasureBetweenData:dataPause1 andData:dataPause1];
    float similarity1_2 = [self.similarityDetector similarityMeasureBetweenData:dataPause1 andData:dataPause2];
    STAssertTrue(similarity1_1 < similarity1_2, @"Demonstrate that receive wrong results with uneven amplitude");
}

- (void)testCompareSignalOfTheSameAmplitude
{
    NSData *referenceData = [self dataWithPattern:2, 100.0, 1.0];
    NSData *dataPause1 = [self dataWithPattern:2, 1.0, 0.0];
    NSData *dataPause2 = [self dataWithPattern:3, 1.0, 0.0, 0.0];
    float similarity1 = [self.similarityDetector similarityMeasureBetweenData:referenceData andData:dataPause1];
    float similarity2 = [self.similarityDetector similarityMeasureBetweenData:referenceData andData:dataPause2];
    STAssertTrue(similarity1 > similarity2, nil);
}

- (void)testSimilarityIsKindaLinear
{
    NSData *referenceData = [self dataWithPattern:3, 1.0, 0.0, 0.0];
    NSData *dataPause1 = [self dataWithPattern:2, 1.0, 0.0];
    NSData *dataPause3 = [self dataWithPattern:4, 1.0, 0.0, 0.0, 0.0];
    NSData *dataPause4 = [self dataWithPattern:5, 1.0, 0.0, 0.0, 0.0, 0.0];
    float similarity1 = [self.similarityDetector similarityMeasureBetweenData:referenceData andData:dataPause1];
    float similarity3 = [self.similarityDetector similarityMeasureBetweenData:referenceData andData:dataPause3];
    float similarity4 = [self.similarityDetector similarityMeasureBetweenData:referenceData andData:dataPause4];
    STAssertTrue(similarity1 > similarity4, nil);
    STAssertTrue(similarity3 > similarity4, nil);
}

#pragma mark - Helpers

- (NSData *)dataWithPattern:(NSInteger)valuesCount, ...
{
    NSParameterAssert(valuesCount > 0);
    NSMutableData *pattern = [[NSMutableData alloc] initWithLength:(valuesCount * sizeof(float))];
    float *patternBuffer = (float *)[pattern mutableBytes];
    va_list values;
    va_start(values, valuesCount);
    for (NSInteger i = 0; i < valuesCount; i++)
    {
        patternBuffer[i] = (float)va_arg(values, double);
    }
    va_end(values);
    return [RDRepeatedDataGenerator generateDataWithPattern:pattern length:kLength];
}

@end
