//
//  RDHistoryBuffer.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/6/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

// RDHistoryBuffer represents a buffer of fixed length.  When you add more
// values, old values are pushed out.
@interface RDHistoryBuffer : NSObject
- (id)initWithLength:(NSUInteger)length;

- (void)addValue:(double)value;

- (double)average;
- (double)variance;
@end
