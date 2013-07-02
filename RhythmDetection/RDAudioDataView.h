//
//  RDAudioDataView.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/2/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RDAudioData;

@interface RDAudioDataView : NSView
@property (strong, nonatomic) RDAudioData *audioData;
@end
