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
const CGFloat kLeftPadding = 0.0;
const CGFloat kVerticalPadding = 5.0;
const CGFloat kPositionMarkerScrollingOffset = 40.0;

@interface RDAudioDataView()
@property (assign, nonatomic) NSUInteger samplesCount;
@end

@implementation RDAudioDataView

- (void)reloadData
{
    self.samplesCount = [self.dataSource numberOfSamplesInAudioDataView:self];
    self.position = 0;
    NSScrollView *scrollView = [self enclosingScrollView];
    if (nil != scrollView)
    {
        CGFloat minWidth = NSWidth([scrollView frame]);
        CGFloat dataWidth = self.samplesCount * kStep;
        CGFloat width = fmax(minWidth, dataWidth);
        NSSize frameSize = [self frame].size;
        frameSize.width = width;
        [self setFrameSize:frameSize];
    }
    [self setNeedsDisplay:YES];
}

- (CGFloat)xCoordinateForSampleIndex:(NSUInteger)index
{
    return kLeftPadding + kStep * index;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    // Draw background.
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);

    // Draw values.
    NSBezierPath *path = [NSBezierPath bezierPath];
    AudioSampleType min = [self.dataSource minValueInAudioDataView:self];
    AudioSampleType max = [self.dataSource maxValueInAudioDataView:self];
    CGFloat height = NSHeight([self bounds]) - 2 * kVerticalPadding;
    NSUInteger startIndex = (NSUInteger)floor(NSMinX(dirtyRect) / kStep);
    NSUInteger endIndex = (NSUInteger)ceil(NSMaxX(dirtyRect) / kStep) + 1;  // +1 because endIndex is excluded
    endIndex = (NSUInteger)fmin(endIndex, self.samplesCount);
    for (NSUInteger i = startIndex; i < endIndex; i++)
    {
        CGFloat x = [self xCoordinateForSampleIndex:i];

        AudioSampleType value = [self.dataSource audioDataView:self sampleValueAtIndex:i];
        CGFloat normalizedY = (value - min) / (max - min);
        CGFloat y = height * normalizedY + kVerticalPadding;

        NSPoint point = NSMakePoint(x, y);
        if (i > startIndex)
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

    // Draw current position marker.
    NSUInteger position = self.position;
    if ((startIndex <= position) && (position < endIndex))
    {
        CGFloat x = [self xCoordinateForSampleIndex:position];
        CGFloat fullHeight = NSHeight([self bounds]);
        [[NSColor redColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0.0)
                                  toPoint:NSMakePoint(x, fullHeight)];
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (void)setPosition:(NSUInteger)position
{
    if (_position != position)
    {
        // Mark old position dirty.
        CGFloat x = [self xCoordinateForSampleIndex:_position];
        CGFloat fullHeight = NSHeight([self bounds]);
        [self setNeedsDisplayInRect:NSMakeRect(x - 1.0, 0.0, 2.0, fullHeight)];
        // Mark new position dirty.
        x = [self xCoordinateForSampleIndex:position];
        [self setNeedsDisplayInRect:NSMakeRect(x - 1.0, 0.0, 2.0, fullHeight)];
        _position = position;
    }
}

- (void)scrollToCurrentPosition
{
    NSClipView *clipView = [[self enclosingScrollView] contentView];
    if (nil != clipView)
    {
        CGFloat positionMarkerX = [self xCoordinateForSampleIndex:self.position];
        // Don't want current position marker at the left edge, but with a little offset to the right.
        NSPoint scrollPoint = NSMakePoint(positionMarkerX - kPositionMarkerScrollingOffset, 0.0);
        scrollPoint = [clipView constrainScrollPoint:scrollPoint];
        [clipView scrollToPoint:scrollPoint];
    }
}

@end
