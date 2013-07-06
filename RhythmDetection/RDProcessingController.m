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
@end

@implementation RDProcessingController

- (void)loadFileAtURL:(NSURL *)fileUrl
{
    RDAudioFile *file = [[RDAudioFile alloc] initWithURL:fileUrl];
    self.audioPlayback = [[RDAudioPlayback alloc] initWithAudioFile:file];
    RDAudioData *audioData = [[RDAudioData alloc] initWithData:[file monoPCMRepresentation]];
    self.audioData = audioData;
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

- (void)setAudioData:(RDAudioData *)audioData
{
    if (audioData != _audioData)
    {
        _audioData = audioData;

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

@end
