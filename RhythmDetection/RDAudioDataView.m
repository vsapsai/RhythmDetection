//
//  RDAudioDataView.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/2/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAudioDataView.h"
#import "RDAudioData.h"

const CGFloat kStep = 2.0;

@interface RDAudioDataView()
@property (strong, nonatomic) NSNumber *startIndex;
@end

@implementation RDAudioDataView

- (void)setAudioData:(RDAudioData *)audioData
{
    if (audioData != _audioData)
    {
        _audioData = audioData;
        [self setNeedsDisplay:YES];
        self.startIndex = nil;
    }
}

- (NSNumber *)startIndex
{
    if ((_startIndex == nil) && (self.audioData != nil))
    {
        NSUInteger index = NSNotFound;
        RDAudioData *data = self.audioData;
        for (NSUInteger i = 0; i < data.length; i++)
        {
            AudioSampleType sample = [data valueAtIndex:i];
            if (fabs(sample) > 0.1)
            {
                index = i;
                break;
            }
        }
        _startIndex = @(index);
    }
    return _startIndex;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    // Draw background.
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);

    // Draw values.
    NSBezierPath *path = [NSBezierPath bezierPath];
    RDAudioData *data = self.audioData;
    NSUInteger startIndex = (nil != self.startIndex) ? [self.startIndex unsignedIntegerValue] : NSNotFound;
    if (startIndex != NSNotFound)
    {
        NSUInteger nonZeroLength = (data.length - startIndex);
        NSUInteger drawSamplesCount = (NSUInteger)fmin(nonZeroLength, NSWidth([self bounds]));
        AudioSampleType min = -1.0, max = 1.0;
        for (NSUInteger i = 0; i < drawSamplesCount; i++)
        {
            CGFloat x = 0.0 + kStep * i;

            AudioSampleType value = [data valueAtIndex:(startIndex + i)];
            CGFloat normalizedY = (value - min) / (max - min);
            CGFloat y = NSHeight([self bounds]) * normalizedY;

            NSPoint point = NSMakePoint(x, y);
            if (i > 0)
            {
                [path lineToPoint:point];
            }
            else
            {
                [path moveToPoint:point];
            }
        }
    }
    [[NSColor blackColor] set];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}

@end
