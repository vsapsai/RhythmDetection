//
//  RDFFTProcessor.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/22/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDFFTProcessor : NSObject
- (id)initWithFramesCount:(UInt32)framesCount;

//TODO(vsapsai): use outBuffer two times smaller than inBuffer
- (void)writeSpectrumEnergyForData:(const float *)inBuffer toBuffer:(float *)outBuffer;
@end
