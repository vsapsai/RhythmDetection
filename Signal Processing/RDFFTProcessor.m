//
//  RDFFTProcessor.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/22/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDFFTProcessor.h"
#import <Accelerate/Accelerate.h>
#import "RDDSPSplitComplex.h"

@interface RDFFTProcessor()
@property (assign, nonatomic) UInt32 framesCount;
@property (assign, nonatomic) UInt32 log2N;
@property (assign, nonatomic) FFTSetup fftSetup;
@property (strong, nonatomic) RDDSPSplitComplex *splitComplex;
@end

@implementation RDFFTProcessor

- (id)initWithFramesCount:(UInt32)framesCount
{
    NSParameterAssert(framesCount > 1);
    self = [super init];
    if (nil != self)
    {
        self.framesCount = framesCount;
        UInt32 log2N = (UInt32)ceil(log2(framesCount));
        NSAssert(framesCount == (1 << log2N), @"Support only power of 2 frames count");
        self.log2N = log2N;
        self.fftSetup = vDSP_create_fftsetup(log2N, kFFTRadix2);
        NSParameterAssert(NULL != self.fftSetup);
        self.splitComplex = [[RDDSPSplitComplex alloc] initWithLength:(framesCount / 2)];
    }
    return self;
}

- (void)dealloc
{
    vDSP_destroy_fftsetup(self.fftSetup);
    self.fftSetup = NULL;
}

- (void)writeSpectrumEnergyForData:(const float *)inBuffer toBuffer:(float *)outBuffer
{
    NSUInteger fftLength = (self.framesCount / 2);
    DSPSplitComplex dspSplitComplex = [self.splitComplex dspSplitComplex];
    vDSP_ctoz((const DSPComplex *)inBuffer, 2, &dspSplitComplex, 1, fftLength);
    vDSP_fft_zrip(self.fftSetup, &dspSplitComplex, 1, self.log2N, kFFTDirection_Forward);
    memset(outBuffer, 0, self.framesCount * sizeof(float));
    outBuffer[fftLength] = dspSplitComplex.imagp[0] * dspSplitComplex.imagp[0];
    dspSplitComplex.imagp[0] = 0.0;
    vDSP_zvmags(&dspSplitComplex, 1, outBuffer, 1, fftLength);
}

@end
