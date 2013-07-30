//
//  RDViewController.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/28/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDViewController.h"
#import "RDDataSimilarityDetector.h"

static const NSUInteger kSamplesCount = 4096;

@interface RDViewController()
@end

@implementation RDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [(RDRhythmView *)self.view setTouchesCount:8];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RDRhythmViewDelegate

- (void)rhythmView:(RDRhythmView *)view didReceiveTouchesAtTimes:(NSArray *)touchTimes
{
    NSLog(@"average time interval = %f", [self averageTimeInterval:touchTimes]);
    [self detectRhythmFromTouchSignal:touchTimes];
}

#pragma mark -

- (NSTimeInterval)averageTimeInterval:(NSArray *)times
{
    NSParameterAssert([times count] >= 2);
    NSTimeInterval total = 0.0;
    NSDate *previousTime = nil;
    for (NSDate *time in times)
    {
        if (nil != previousTime)
        {
            total += [time timeIntervalSinceDate:previousTime];
        }
        previousTime = time;
    }
    return total / ([times count] - 1);
}

- (void)detectRhythmFromTouchSignal:(NSArray *)touchTimes
{
    NSData *referenceData = [self generateTouchSignal:touchTimes];
    float samplingRate = kSamplesCount / [self touchesDuration:touchTimes];
    RDDataSimilarityDetector *similarityDetector = [[RDDataSimilarityDetector alloc] initWithLength:kSamplesCount];
    for (NSTimeInterval signalInterval = 0.3; signalInterval <= 0.9; signalInterval += 0.02)
    {
        NSData *periodicSignal = [self generatePeriodicSignalAtInterval:signalInterval samplingRate:samplingRate];
        float similarity = [similarityDetector similarityMeasureBetweenData:referenceData andData:periodicSignal];
        NSLog(@"similarity at interval %f = %f", signalInterval, similarity);
    }
    {
        NSData *periodicSignal = [self generatePeriodicSignalAtInterval:[self averageTimeInterval:touchTimes] samplingRate:samplingRate];
        float similarity = [similarityDetector similarityMeasureBetweenData:referenceData andData:periodicSignal];
        NSLog(@"similarity at average interval = %f", similarity);
    }
    {
        float similarity = [similarityDetector similarityMeasureBetweenData:referenceData andData:referenceData];
        NSLog(@"similarity with itself = %f", similarity);
    }
}

- (NSTimeInterval)touchesDuration:(NSArray *)touchTimes
{
    NSDate *startTime = touchTimes[0];
    NSDate *endTime = [touchTimes lastObject];
    NSTimeInterval duration = [endTime timeIntervalSinceDate:startTime];
    return duration;
}

- (NSData *)generateTouchSignal:(NSArray *)touchTimes
{
    NSParameterAssert([touchTimes count] >= 2);
    NSDate *startTime = touchTimes[0];
    NSTimeInterval duration = [self touchesDuration:touchTimes];
    NSMutableData *touchSignal = [[NSMutableData alloc] initWithLength:(kSamplesCount * sizeof(float))];
    float *signalBuffer = (float *)[touchSignal mutableBytes];
    for (NSDate *time in touchTimes)
    {
        NSTimeInterval timeFromStart = [time timeIntervalSinceDate:startTime];
        NSUInteger sampleIndex = (timeFromStart / duration) * kSamplesCount;
        signalBuffer[sampleIndex] = 1.0;
    }
    return touchSignal;
}

- (NSData *)generatePeriodicSignalAtInterval:(NSTimeInterval)signalInterval samplingRate:(float)samplingRate
{
    NSMutableData *signal = [[NSMutableData alloc] initWithLength:(kSamplesCount * sizeof(float))];
    float *signalBuffer = (float *)[signal mutableBytes];
    NSUInteger intervalSamples = signalInterval * samplingRate;
    //NSLog(@"samples for interval %f = %ld", signalInterval, (unsigned long)intervalSamples);
    for (NSUInteger signalIndex = 0; signalIndex < kSamplesCount; signalIndex += intervalSamples)
    {
        signalBuffer[signalIndex] = 1.0;
    }
    return signal;
}

@end
