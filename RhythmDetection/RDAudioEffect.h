//
//  RDAudioEffect.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/15/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RDBufferList;

// Wrapper around effect AudioUnit.
@interface RDAudioEffect : NSObject

+ (id)lowPassFilterWithCutoffFrequency:(float)cutoffFrequency;

- (RDBufferList *)processBufferList:(RDBufferList *)bufferList;

@end
