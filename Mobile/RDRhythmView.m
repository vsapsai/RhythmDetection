//
//  RDRhythmView.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/28/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDRhythmView.h"
#import <QuartzCore/QuartzCore.h>

static const NSUInteger kBeatsCount = 8;
static const CGFloat kStrongBeatHeightProportion = 0.6;
static const CGFloat kBeatHeightProportion = 0.4;
static const CGFloat kBeatEmptyWidthProportion = 0.5;
static const CGFloat kBeatRectCornerRadius = 10.;

@interface RDRhythmView()
@property (strong, nonatomic) NSMutableArray *touchTimes;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) UIColor *borderColor;
@property (strong, nonatomic) UIColor *activeColor;
@property (strong, nonatomic) UIColor *activeBorderColor;

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) NSTimeInterval animationPeriod;
@property (strong, nonatomic) NSDate *animationStartTime;
@end

@implementation RDRhythmView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (nil != self)
    {
        [self setUpView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (nil != self)
    {
        [self setUpView];
    }
    return self;
}

- (void)dealloc
{
    [self.displayLink invalidate];
}

- (UIColor *)colorWithByteRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue
{
    return [UIColor colorWithRed:(red / 255.) green:(green / 255.) blue:(blue / 255.) alpha:1.0];
}

- (void)setUpView
{
    self.touchTimes = [NSMutableArray array];
    self.backgroundColor = [self colorWithByteRed:209 green:255 blue:242];
    self.color = [self colorWithByteRed:168 green:160 blue:255];
    self.borderColor = [self colorWithByteRed:138 green:125 blue:232];
    self.activeColor = [self colorWithByteRed:139 green:124 blue:255];
    self.activeBorderColor = [self colorWithByteRed:98 green:80 blue:208];

    self.animating = NO;
}

- (void)didMoveToWindow
{
    if (nil != self.window)
    {
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        displayLink.paused = YES;
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = displayLink;
    }
    else
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

#pragma mark -

- (void)drawRect:(CGRect)rect
{
    CGRect bounds = self.bounds;
    CGFloat totalWidth = CGRectGetWidth(bounds);
    CGFloat totalHeight = CGRectGetHeight(bounds);

    CGFloat beatWidth = (totalWidth / kBeatsCount);
    CGFloat beatEmptyWidth = (beatWidth * kBeatEmptyWidthProportion);
    CGFloat beatRectWidth = (beatWidth - beatEmptyWidth);
    CGFloat xOffset = beatEmptyWidth / 2.;
    CGFloat animationOffset = 0.;
    if (self.animating)
    {
        NSDate *now = [NSDate date];
        NSTimeInterval inPeriodOffset = fmod([now timeIntervalSinceDate:self.animationStartTime], self.animationPeriod);
        animationOffset = totalWidth * (inPeriodOffset / self.animationPeriod);
        animationOffset += xOffset;
        animationOffset = fmod(animationOffset, totalWidth);
    }

    for (NSUInteger beatIndex = 0; beatIndex < kBeatsCount; beatIndex++)
    {
        BOOL isPauseBeat = ((beatIndex % 4) == 3);
        BOOL isStrongBeat = ((beatIndex % 4) == 0);
        BOOL isBeforePauseBeat = ((beatIndex % 4) == 2);

        // Geometry.
        CGFloat beatHeightProportion = (isStrongBeat ? kStrongBeatHeightProportion : kBeatHeightProportion);
        CGFloat beatRectHeight = totalHeight * beatHeightProportion;
        CGRect beatRect = CGRectMake(xOffset, 0., beatRectWidth, beatRectHeight);

        // Create path.
        BOOL isAnimationOffsetWithinPath = NO;
        UIBezierPath *path = nil;
        if (isBeforePauseBeat)
        {
            path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(xOffset, 0.)];
            [path addLineToPoint:CGPointMake(xOffset, beatRectHeight - kBeatRectCornerRadius)];
            [path addArcWithCenter:CGPointMake(xOffset + kBeatRectCornerRadius, beatRectHeight - kBeatRectCornerRadius)
                            radius:kBeatRectCornerRadius
                        startAngle:M_PI
                          endAngle:M_PI_2
                         clockwise:NO];
            CGFloat xHalfRect = (xOffset + beatRectWidth / 2.);
            CGFloat xSlopeEnd = (xOffset + beatRectWidth + beatWidth);
            [path addLineToPoint:CGPointMake(xHalfRect, beatRectHeight)];
            [path addCurveToPoint:CGPointMake(xSlopeEnd, 0.)
                    controlPoint1:CGPointMake(xHalfRect + 30., beatRectHeight)
                    controlPoint2:CGPointMake(xSlopeEnd - 80., 0.)];
            [path closePath];
            isAnimationOffsetWithinPath = ((xOffset <= animationOffset) && (animationOffset <= xSlopeEnd));
        }
        else if (!isPauseBeat)
        {
            path = [UIBezierPath bezierPathWithRoundedRect:beatRect byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(kBeatRectCornerRadius, kBeatRectCornerRadius)];
            isAnimationOffsetWithinPath = ((xOffset <= animationOffset) && (animationOffset <= CGRectGetMaxX(beatRect)));
        }

        // Draw.
        if (nil != path)
        {
            // Color.
            BOOL isActiveBeat = (self.animating && isAnimationOffsetWithinPath);
            if (isActiveBeat)
            {
                [self.activeColor setFill];
                [self.activeBorderColor setStroke];
            }
            else
            {
                [self.color setFill];
                [self.borderColor setStroke];
            }
            [path fill];
            [path stroke];
        }

        xOffset += beatWidth;
    }

    if (self.animating)
    {
        [[UIColor colorWithRed:1. green:0. blue:0. alpha:.5] set];
        UIRectFill(CGRectMake(animationOffset - 1., 0., 2., totalHeight));
    }
}

#pragma mark - Animation

- (void)displayLinkDidFire:(id)sender
{
    [self setNeedsDisplay];
}

- (void)startAnimationWithPeriod:(NSTimeInterval)animationPeriod startTime:(NSDate *)startTime
{
    NSParameterAssert(animationPeriod > 0.);
    NSParameterAssert(nil != startTime);
    self.animationPeriod = animationPeriod;
    self.animationStartTime = startTime;
    self.animating = YES;
    self.displayLink.paused = NO;
}

- (void)stopAnimation
{
    self.animating = NO;
    self.displayLink.paused = YES;
    [self setNeedsDisplay];
}

#pragma mark - Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSDate *touchTime = [NSDate date];
    [self.touchTimes addObject:touchTime];
    if ([self.touchTimes count] >= self.touchesCount)
    {
        [self.delegate rhythmView:self didReceiveTouchesAtTimes:self.touchTimes];
        [self.touchTimes removeAllObjects];
    }
    [super touchesBegan:touches withEvent:event];
}

@end
