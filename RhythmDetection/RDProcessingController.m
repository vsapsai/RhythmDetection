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

@interface RDProcessingController()
@property (strong, nonatomic) RDAudioPlayback *audioPlayback;
@property (strong, nonatomic) RDAudioData *audioData;
@property (assign, nonatomic) NSUInteger audioDataStartIndex;
@property (assign, nonatomic, getter=isReady) BOOL ready;
@end

@implementation RDProcessingController

- (void)loadFileAtURL:(NSURL *)fileUrl
{
    [NSThread detachNewThreadSelector:@selector(_loadFileAtURL:) toTarget:self withObject:fileUrl];
}

- (void)_loadFileAtURL:(NSURL *)fileUrl
{
    @autoreleasepool
    {
        RDAudioFile *file = [[RDAudioFile alloc] initWithURL:fileUrl];
        self.audioPlayback = [[RDAudioPlayback alloc] initWithAudioFile:file];
        RDAudioData *audioData = [[RDAudioData alloc] initWithData:[file monoPCMRepresentation]];
        [self performSelectorOnMainThread:@selector(didLoadAudioData:) withObject:audioData waitUntilDone:NO];
    }
}

- (void)didLoadAudioData:(RDAudioData *)audioData
{
    self.ready = YES;
    //[self displayNonZeroAudioData:audioData];
    [self displayAudioData:[self computeEnergyBuckets:audioData]];
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
    [self.playbackProgressSlider setFloatValue:self.audioPlayback.currentProgress];
}

- (IBAction)setProgress:(id)sender
{
    self.audioPlayback.currentProgress = [sender floatValue];
}

#pragma mark Data processing

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
