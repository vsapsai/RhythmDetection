//
//  RDFFTProcessor.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/22/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDFFTProcessor.h"
#import <Accelerate/Accelerate.h>

@interface RDFFTProcessor()
@property (assign, nonatomic) UInt32 framesCount;
@property (assign, nonatomic) UInt32 log2N;
@property (assign, nonatomic) FFTSetup fftSetup;
@property (assign, nonatomic) DSPSplitComplex dspSplitComplex;
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
        DSPSplitComplex splitComplex;
        splitComplex.realp = (float *)calloc(framesCount, sizeof(float));
        splitComplex.imagp = (float *)calloc(framesCount, sizeof(float));
        self.dspSplitComplex = splitComplex;
    }
    return self;
}

- (void)dealloc
{
    vDSP_destroy_fftsetup(self.fftSetup);
    self.fftSetup = NULL;
    free(self.dspSplitComplex.realp);
    free(self.dspSplitComplex.imagp);
}

- (void)writeSpectrumEnergyForData:(const float *)inBuffer toBuffer:(float *)outBuffer
{
    DSPSplitComplex dspSplitComplex = self.dspSplitComplex;
    memcpy(dspSplitComplex.realp, inBuffer, self.framesCount * sizeof(float));
    memset(dspSplitComplex.imagp, 0, self.framesCount * sizeof(float));
    vDSP_fft_zrip(self.fftSetup, &dspSplitComplex, 1, self.log2N, kFFTDirection_Forward);
    vDSP_zvmags(&dspSplitComplex, 1, outBuffer, 1, self.framesCount);
}

@end
