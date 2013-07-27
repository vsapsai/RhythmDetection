//
//  RDHistoryBuffer.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/6/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDHistoryBuffer.h"

@interface RDHistoryBuffer()
@property (strong, nonatomic) NSMutableData *buffer;
@property (assign, nonatomic) double sum;
@property (assign, nonatomic) NSUInteger replacementIndex;
@end

@implementation RDHistoryBuffer

- (id)initWithLength:(NSUInteger)length
{
    NSParameterAssert(length > 0);
    self = [super init];
    if (nil != self)
    {
        self.buffer = [NSMutableData dataWithLength:(length * sizeof(double))];
        self.sum = 0.0;
        self.replacementIndex = 0;
    }
    return self;
}

- (NSUInteger)length
{
    return self.buffer.length / sizeof(double);
}

- (void)addValue:(double)value
{
    double *rawBuffer = (double *)[self.buffer mutableBytes];
    self.sum -= rawBuffer[self.replacementIndex];
    self.sum += value;
    rawBuffer[self.replacementIndex] = value;
    self.replacementIndex = (self.replacementIndex + 1) % self.length;
}

- (double)average
{
    return self.sum / self.length;
}

- (double)variance
{
    double result = 0.0;
    double average = self.average;
    double *rawBuffer = (double *)[self.buffer mutableBytes];
    NSUInteger length = self.length;
    for (NSUInteger i = 0; i < length; i++)
    {
        double difference = rawBuffer[i] - average;
        result += difference * difference;
    }
    return result / length;
}

@end
