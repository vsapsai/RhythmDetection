//
//  RDAudioDataView.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/2/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudioTypes.h>

@protocol RDAudioDataViewDataSource;

@interface RDAudioDataView : NSView
@property (weak, nonatomic) IBOutlet id<RDAudioDataViewDataSource> dataSource;

- (void)reloadData;
@end

@protocol RDAudioDataViewDataSource <NSObject>
- (NSUInteger)numberOfSamplesInAudioDataView:(RDAudioDataView *)audioDataView;
- (AudioSampleType)audioDataView:(RDAudioDataView *)audioDataView sampleValueAtIndex:(NSUInteger)sampleIndex;
- (AudioSampleType)minValueInAudioDataView:(RDAudioDataView *)audioDataView;
- (AudioSampleType)maxValueInAudioDataView:(RDAudioDataView *)audioDataView;
@end
