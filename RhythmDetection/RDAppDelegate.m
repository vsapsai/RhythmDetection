//
//  RDAppDelegate.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import "RDAudioPlayback.h"
#import "RDAudioFile.h"
#import "RDAudioData.h"
#import "RDAudioDataView.h"

@interface RDAppDelegate()
@property (strong, nonatomic) RDAudioPlayback *audioPlayback;
@end

@implementation RDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *filePath = @"~/Music/iTunes/iTunes Media/Music/The Rolling Stones/Hot Rocks 1964-1971/1-09 Paint It Black.m4a";
    filePath = [filePath stringByExpandingTildeInPath];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
    self.audioPlayback = [[RDAudioPlayback alloc] initWithURL:fileUrl];
    RDAudioFile *file = [[RDAudioFile alloc] initWithURL:fileUrl];
    RDAudioData *audioData = [[RDAudioData alloc] initWithData:[file PCMRepresentation]];
    self.audioDataView.audioData = audioData;
}

- (IBAction)start:(id)sender
{
    [self.audioPlayback start];
}

- (IBAction)stop:(id)sender
{
    [self.audioPlayback stop];
}

@end
