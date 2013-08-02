//
//  RDDataSimilarityDetector.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDDataSimilarityDetector.h"
#import <Accelerate/Accelerate.h>
#import "RDDSPSplitComplex.h"

@interface RDDataSimilarityDetector()
@property (assign, nonatomic) vDSP_Length fftLength;
@property (assign, nonatomic) vDSP_Length log2N;
@property (assign, nonatomic) FFTSetup fftSetup;

@property (strong, nonatomic) RDDSPSplitComplex *splitComplex1;
@property (strong, nonatomic) RDDSPSplitComplex *splitComplex2;
@property (strong, nonatomic) RDDSPSplitComplex *result;
@property (strong, nonatomic) NSMutableData *resultBuffer;
@end

@implementation RDDataSimilarityDetector

- (id)initWithLength:(NSUInteger)length
{
    NSParameterAssert(length > 1);
    self = [super init];
    if (nil != self)
    {
        vDSP_Length log2N = (vDSP_Length)ceil(log2(length));
        NSAssert(length == (1 << log2N), @"Support only power of 2 length");
        self.fftSetup = vDSP_create_fftsetup(log2N, kFFTRadix2);
        NSParameterAssert(NULL != self.fftSetup);
        self.log2N = log2N;
        NSUInteger fftLength = (length / 2);
        self.fftLength = fftLength;
        self.splitComplex1 = [[RDDSPSplitComplex alloc] initWithLength:fftLength];
        self.splitComplex2 = [[RDDSPSplitComplex alloc] initWithLength:fftLength];
        self.result = [[RDDSPSplitComplex alloc] initWithLength:fftLength];
        self.resultBuffer = [[NSMutableData alloc] initWithLength:(fftLength * sizeof(float))];
    }
    return self;
}

- (void)dealloc
{
    vDSP_destroy_fftsetup(self.fftSetup);
    self.fftSetup = NULL;
}

- (float)similarityMeasureBetweenData:(NSData *)data1 andData:(NSData *)data2
{
    NSParameterAssert([data1 length] == (2 * self.fftLength * sizeof(float)));
    NSParameterAssert([data2 length] == (2 * self.fftLength * sizeof(float)));
    NSUInteger fftLength = self.fftLength;
    DSPSplitComplex dspSplitComplex1 = [self.splitComplex1 dspSplitComplex];
    vDSP_ctoz((const DSPComplex *)[data1 bytes], 2, &dspSplitComplex1, 1, fftLength);
    vDSP_fft_zrip(self.fftSetup, &dspSplitComplex1, 1, self.log2N, kFFTDirection_Forward);

    DSPSplitComplex dspSplitComplex2 = [self.splitComplex2 dspSplitComplex];
    vDSP_ctoz((const DSPComplex *)[data2 bytes], 2, &dspSplitComplex2, 1, fftLength);
    vDSP_fft_zrip(self.fftSetup, &dspSplitComplex2, 1, self.log2N, kFFTDirection_Forward);

    // For explanation about realp[0], imagp[0] see Data packing for real
    // one-dimensional FFTs.
    float realPartConvolution[] = {dspSplitComplex1.realp[0] * dspSplitComplex2.realp[0],
        dspSplitComplex1.imagp[0] * dspSplitComplex2.imagp[0]};
    float realPartMagnitudeSum = realPartConvolution[0] * realPartConvolution[0] + realPartConvolution[1] * realPartConvolution[1];
    dspSplitComplex1.imagp[0] = 0.0;
    dspSplitComplex1.realp[0] = 0.0;
    dspSplitComplex2.imagp[0] = 0.0;
    dspSplitComplex2.realp[0] = 0.0;

    DSPSplitComplex resultDSPSplitComplex = [self.result dspSplitComplex];
    vDSP_zvmul(&dspSplitComplex1, 1, &dspSplitComplex2, 1, &resultDSPSplitComplex, 1, fftLength, 1);

    float *magnitudes = [self.resultBuffer mutableBytes];
    vDSP_zvmags(&resultDSPSplitComplex, 1, magnitudes, 1, fftLength);
    float magnitudeSum = 0.0;
    vDSP_sve(magnitudes, 1, &magnitudeSum, fftLength);
    
    return magnitudeSum + realPartMagnitudeSum;
}

@end
