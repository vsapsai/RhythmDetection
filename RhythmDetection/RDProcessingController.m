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
@end

@implementation RDProcessingController

- (void)loadFileAtURL:(NSURL *)fileUrl
{
    self.audioPlayback = [[RDAudioPlayback alloc] initWithURL:fileUrl];
    RDAudioFile *file = [[RDAudioFile alloc] initWithURL:fileUrl];
    RDAudioData *audioData = [[RDAudioData alloc] initWithData:[file PCMRepresentation]];
    self.audioDataView.audioData = audioData;
    [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30) target:self selector:@selector(updatePlaybackProgress:) userInfo:nil repeats:YES];
}

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

@end
