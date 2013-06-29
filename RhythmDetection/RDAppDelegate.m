//
//  RDAppDelegate.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAppDelegate.h"
#import "RDAudioPlayback.h"

@interface RDAppDelegate()
@property (strong, nonatomic) RDAudioPlayback *audioProcessor;
@end

@implementation RDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *filePath = @"~/Music/iTunes/iTunes Media/Music/The Rolling Stones/Hot Rocks 1964-1971/1-09 Paint It Black.m4a";
    filePath = [filePath stringByExpandingTildeInPath];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
    self.audioProcessor = [[RDAudioPlayback alloc] initWithURL:fileUrl];
}

- (IBAction)start:(id)sender
{
    [self.audioProcessor start];
}

- (IBAction)stop:(id)sender
{
    [self.audioProcessor stop];
}

@end
