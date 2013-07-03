//
//  RDAppDelegate.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RDAudioDataView;

@interface RDAppDelegate : NSObject <NSApplicationDelegate>

@property (weak, nonatomic) IBOutlet NSWindow *window;
@property (weak, nonatomic) IBOutlet RDAudioDataView *audioDataView;
@property (weak, nonatomic) IBOutlet NSSlider *playbackProgressSlider;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;

@end
