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

@implementation RDAudioDataView

- (void)reloadData
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    // Draw background.
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);

    // Draw values.
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSUInteger dataLength = [self.dataSource numberOfSamplesInAudioDataView:self];
    NSUInteger drawableLength = (NSUInteger)(NSWidth([self bounds]) / kStep);
    dataLength = (NSUInteger)fmin(dataLength, drawableLength);
    AudioSampleType min = -1.0, max = 1.0;
    for (NSUInteger i = 0; i < dataLength; i++)
    {
        CGFloat x = 0.0 + kStep * i;

        AudioSampleType value = [self.dataSource audioDataView:self sampleValueAtIndex:i];
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
    [[NSColor blackColor] set];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}

@end
