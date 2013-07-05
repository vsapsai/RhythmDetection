//
//  RDProcessingController.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/6/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RDAudioDataView;

@interface RDProcessingController : NSObject
@property (weak, nonatomic) IBOutlet RDAudioDataView *audioDataView;
@property (weak, nonatomic) IBOutlet NSSlider *playbackProgressSlider;

- (void)loadFileAtURL:(NSURL *)fileUrl;

- (IBAction)start:(id)sender;
- (IBAction)pause:(id)sender;
@end
