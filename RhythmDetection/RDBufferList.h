//
//  RDBufferList.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/4/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

// Wrapper around AudioBufferList
@interface RDBufferList : NSObject
// Designated initializer.  `buffers` is NSArray of NSMutableData.  All
// NSMutableData objects should be of the same size.
- (id)initWithBuffers:(NSArray *)buffers;
- (id)initWithBufferSize:(UInt32)bufferByteSize count:(UInt32)buffersCount;

// Returns internal buffers, so be careful mutating them.
- (NSArray *)buffers;

- (NSUInteger)buffersCount;
- (NSUInteger)bufferSize;

// Returns AudioBufferList for all data.
- (AudioBufferList *)audioBufferList NS_RETURNS_INNER_POINTER;
- (AudioBufferList *)audioBufferListWithRange:(NSRange)range NS_RETURNS_INNER_POINTER;
@end
