//
//  RDDSPSplitComplex.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <vecLib/vDSP.h>

// Objective-C equivalent of DSPSplitComplex.  Responsible for memory management.
@interface RDDSPSplitComplex : NSObject
- (id)initWithLength:(NSUInteger)length;

- (NSUInteger)length;

- (DSPSplitComplex)dspSplitComplex;

- (void)copyAsRealData:(NSData *)data;
- (void)copyAsImaginaryData:(NSData *)data;

- (void)zeroRealData;
- (void)zeroImaginaryData;
@end
