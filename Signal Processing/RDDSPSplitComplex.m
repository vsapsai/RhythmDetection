//
//  RDDSPSplitComplex.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDDSPSplitComplex.h"

@interface RDDSPSplitComplex()
// Don't mutate data itself, only bytes it contains.
@property (strong, nonatomic) NSMutableData *realData;
@property (strong, nonatomic) NSMutableData *imaginaryData;
@end

@implementation RDDSPSplitComplex

- (id)initWithLength:(NSUInteger)length
{
    self = [super init];
    if (nil != self)
    {
        self.realData = [[NSMutableData alloc] initWithLength:(length * sizeof(float))];
        self.imaginaryData = [[NSMutableData alloc] initWithLength:(length * sizeof(float))];
    }
    return self;
}

- (NSUInteger)length
{
    return [self.realData length] / sizeof(float);
}

- (DSPSplitComplex)dspSplitComplex
{
    DSPSplitComplex result = {
        .realp = [self.realData mutableBytes],
        .imagp = [self.imaginaryData mutableBytes]
    };
    return result;
}

- (void)copyAsRealData:(NSData *)data
{
    [self.realData setData:data];
}

- (void)copyAsImaginaryData:(NSData *)data
{
    [self.imaginaryData setData:data];
}

- (void)zeroRealData
{
    memset([self.realData mutableBytes], 0, [self.realData length]);
}

- (void)zeroImaginaryData
{
    memset([self.imaginaryData mutableBytes], 0, [self.imaginaryData length]);
}

@end
