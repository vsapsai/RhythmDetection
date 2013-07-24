//
//  RDProcessingController.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/6/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDProcessingController.h"
#import "RDAudioPlayback.h"
#import "RDAudioFile.h"
#import "RDAudioData.h"
#import "RDAudioDataView.h"
#import "RDHistoryBuffer.h"
#import "RDFFTProcessor.h"

@interface RDProcessingController()
@property (strong, nonatomic) RDAudioFile *audioFile;
@property (strong, nonatomic) RDAudioPlayback *audioPlayback;
@property (strong, nonatomic) RDAudioData *audioData;
@property (assign, nonatomic) NSUInteger audioDataStartIndex;
@property (assign, nonatomic, getter=isReady) BOOL ready;
@end

@implementation RDProcessingController

- (void)loadFileAtURL:(NSURL *)fileUrl
{
    self.ready = NO;
    [NSThread detachNewThreadSelector:@selector(_loadFileAtURL:) toTarget:self withObject:fileUrl];
}

- (void)_loadFileAtURL:(NSURL *)fileUrl
{
    @autoreleasepool
    {
        RDAudioFile *file = [[RDAudioFile alloc] initWithURL:fileUrl];
        self.audioFile = file;
        self.audioPlayback = [[RDAudioPlayback alloc] initWithAudioFile:file];
        RDAudioData *audioData = [[RDAudioData alloc] initWithData:[file monoPCMRepresentation]];
        [self performSelectorOnMainThread:@selector(didLoadAudioData:) withObject:audioData waitUntilDone:NO];
    }
}

- (void)didLoadAudioData:(RDAudioData *)audioData
{
    self.ready = YES;
    NSString *windowTitle = [NSString stringWithFormat:NSLocalizedString(@"RhythmDetection - %@ (%@)", @"window title"), [self.audioFile title], [self.audioFile artist]];
    [[self.audioDataView window] setTitle:windowTitle];

    //[self displayNonZeroAudioData:audioData];
    RDAudioData *beatData = [self computeBeats:audioData];
    [self displayAudioData:beatData];
    [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30) target:self selector:@selector(updatePlaybackProgress:) userInfo:nil repeats:YES];
}

#pragma mark Playback

- (IBAction)start:(id)sender
{
    [self.audioPlayback start];
}

- (IBAction)pause:(id)sender
{
    [self.audioPlayback stop];
}

- (void)updatePlaybackProgress:(NSTimer *)timer
{
    float progress = self.audioPlayback.currentProgress;
    [self.playbackProgressSlider setFloatValue:progress];
    self.audioDataView.position = floor(progress * self.audioData.length);
    [self.audioDataView scrollToCurrentPosition];
}

- (IBAction)setProgress:(id)sender
{
    self.audioPlayback.currentProgress = [sender floatValue];
}

#pragma mark Data processing

- (RDAudioData *)computeBeats:(RDAudioData *)audioData
{
#if 0
    RDAudioData *energyData = [self computeEnergyBuckets:audioData];
    RDAudioData *beatData = [self detectBeats:energyData];
    return beatData;
#else
    NSArray *energyDatas = [self computeEnergyBucketsInFrequencySubbands:audioData];
    NSArray *beatDatas = [self detectBeatsArray:energyDatas];
    RDAudioData *beatData = [self collectBeats:beatDatas];
    return beatData;
#endif
}

- (RDAudioData *)computeEnergyBuckets:(RDAudioData *)audioData
{
    const NSUInteger kBucketSize = 1024;
    const NSUInteger energySamplesCount = audioData.length / kBucketSize;
    NSMutableData *energyData = [[NSMutableData alloc] initWithLength:(energySamplesCount * sizeof(AudioSampleType))];
    AudioSampleType *energyBuffer = (AudioSampleType *)[energyData mutableBytes];
    for (NSInteger i = 0; i < energySamplesCount; i++)
    {
        energyBuffer[i] = 0.0;
        for (NSInteger j = 0; j < kBucketSize; j++)
        {
            AudioSampleType value = [audioData valueAtIndex:(i * kBucketSize + j)];
            energyBuffer[i] += value * value;
        }
    }
    return [[RDAudioData alloc] initWithData:energyData];
}

//TODO(vsapsai): be careful with AudioSampleType and float, they aren't interchangeable
- (NSArray *)computeEnergyBucketsInFrequencySubbands:(RDAudioData *)audioData
{
    const NSUInteger kBucketSize = 1024;
    const NSUInteger kSubbandsCount = 32;
    const NSUInteger energySamplesCount = audioData.length / kBucketSize;
    const NSUInteger subbandSize = kBucketSize / kSubbandsCount;

    // Prepare memory buffers for results.
    float *subbandEnergyBuffers[kSubbandsCount];
    NSMutableArray *subbandEnergies = [NSMutableArray arrayWithCapacity:kSubbandsCount];
    for (NSInteger i = 0; i < kSubbandsCount; i++)
    {
        NSMutableData *energyData = [[NSMutableData alloc] initWithLength:(energySamplesCount * sizeof(float))];
        [subbandEnergies addObject:energyData];
        subbandEnergyBuffers[i] = (float *)[energyData mutableBytes];
    }

    RDFFTProcessor *fftProcessor = [[RDFFTProcessor alloc] initWithFramesCount:kBucketSize];
    const AudioSampleType *rawAudioData = [audioData rawData];
    const float *rawData = (const float *)rawAudioData;
    float *energyBuffer = (float *)calloc(kBucketSize, sizeof(float));
    for (NSInteger bucketIndex = 0; bucketIndex < energySamplesCount; bucketIndex++)
    {
        [fftProcessor writeSpectrumEnergyForData:(rawData + bucketIndex * kBucketSize)
                                        toBuffer:energyBuffer];
        // Split energy into subbands.
        for (NSInteger subbandIndex = 0; subbandIndex < kSubbandsCount; subbandIndex++)
        {
            float subbandEnergy = 0.0f;
            for (NSInteger i = subbandIndex * subbandSize; i < (subbandIndex + 1) * subbandSize; i++)
            {
                subbandEnergy += energyBuffer[i];
            }
            subbandEnergy /= subbandSize;
            subbandEnergyBuffers[subbandIndex][bucketIndex] = subbandEnergy;
        }
    }
    free(energyBuffer);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:kSubbandsCount];
    for (NSData *energyData in subbandEnergies)
    {
        [result addObject:[[RDAudioData alloc] initWithData:energyData]];
    }
    return [result copy];
}

// Returns data where 1.0 means that value has enough energy to influence
// a beat, 0.0 means that value has low energy.
//
// Use Simple sound energy - sensitivity detection algorithm from
// http://archive.gamedev.net/archive/reference/programming/features/beatdetection/index.html
- (RDAudioData *)detectBeats:(RDAudioData *)audioData
{
    const NSUInteger kSlidingWindowSize = 43;  // 43 buckets of size 1024 are approximately 1 second of sound
    const NSUInteger kHalfSlidingWindowSize = kSlidingWindowSize / 2;
    RDHistoryBuffer *historyBuffer = [[RDHistoryBuffer alloc] initWithLength:kSlidingWindowSize];
    NSMutableData *beatData = [[NSMutableData alloc] initWithLength:(audioData.length * sizeof(AudioSampleType))];

    // Init buffers.
    for (NSUInteger i = 0; i < kSlidingWindowSize - 1; i++)
    {
        [historyBuffer addValue:[audioData valueAtIndex:i]];
    }
    AudioSampleType *beatBuffer = (AudioSampleType *)[beatData mutableBytes];
    for (NSUInteger i = 0; i < kHalfSlidingWindowSize; i++)
    {
        // Zero out buffer at the beginning.
        beatBuffer[i] = 0.0;
        // Zero out buffer at the end.
        beatBuffer[audioData.length - 1 - i] = 0.0;
    }

    // Main data processing loop.
    for (NSUInteger i = kHalfSlidingWindowSize; i < audioData.length - kHalfSlidingWindowSize; i++)
    {
        NSUInteger windowEndIndex = i + kHalfSlidingWindowSize;
        [historyBuffer addValue:[audioData valueAtIndex:windowEndIndex]];
        double comparisonConstant = (-0.0025714 * [historyBuffer variance]) + 1.5142857;
        AudioSampleType energyValue = [audioData valueAtIndex:i];
        double beatValue = (energyValue > (comparisonConstant * [historyBuffer average])) ? 1.0 : 0.0;
        beatBuffer[i] = beatValue;
    }
    return [[RDAudioData alloc] initWithData:beatData];
}

// Receives and returns NSArray of RDAudioData.
- (NSArray *)detectBeatsArray:(NSArray *)audioDataArray
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[audioDataArray count]];
    for (RDAudioData *audioData in audioDataArray)
    {
        [result addObject:[self detectBeats:audioData]];
    }
    return [result copy];
}

- (RDAudioData *)collectBeats:(NSArray *)audioDataArray
{
    NSParameterAssert([audioDataArray count] > 0);
    NSUInteger audioDataCount = [audioDataArray count];
    NSUInteger audioDataLength = [[audioDataArray lastObject] length];
    NSMutableData *beatData = [[NSMutableData alloc] initWithLength:(audioDataLength * sizeof(AudioSampleType))];
    AudioSampleType *beatBuffer = (AudioSampleType *)[beatData mutableBytes];
    // Average everything.
    for (NSUInteger i = 0; i < audioDataLength; i++)
    {
        AudioSampleType averageValue = 0.0;
        for (RDAudioData *audioData in audioDataArray)
        {
            averageValue += [audioData valueAtIndex:i];
        }
        averageValue /= audioDataCount;
        beatBuffer[i] = averageValue;
    }
    return [[RDAudioData alloc] initWithData:beatData];
}

#pragma mark Data visualizing

- (void)displayNonZeroAudioData:(RDAudioData *)audioData
{
    self.audioData = audioData;
    
    // Find where non-zero data starts.
    NSUInteger startIndex = 0;
    for (NSUInteger i = 0; i < audioData.length; i++)
    {
        AudioSampleType sample = [audioData valueAtIndex:i];
        if (fabs(sample) > 0.1)
        {
            startIndex = i;
            break;
        }
    }
    self.audioDataStartIndex = startIndex;

    [self.audioDataView reloadData];
}

- (void)displayAudioData:(RDAudioData *)audioData
{
    self.audioData = audioData;
    self.audioDataStartIndex = 0;
    [self.audioDataView reloadData];
}

#pragma mark RDAudioDataViewDataSource

- (NSUInteger)numberOfSamplesInAudioDataView:(RDAudioDataView *)audioDataView
{
    return self.audioData.length;
}

- (AudioSampleType)audioDataView:(RDAudioDataView *)audioDataView sampleValueAtIndex:(NSUInteger)sampleIndex
{
    return [self.audioData valueAtIndex:(sampleIndex + self.audioDataStartIndex)];
}

- (AudioSampleType)minValueInAudioDataView:(RDAudioDataView *)audioDataView
{
    return self.audioData.minValue;
}

- (AudioSampleType)maxValueInAudioDataView:(RDAudioDataView *)audioDataView
{
    return self.audioData.maxValue;
}

@end
