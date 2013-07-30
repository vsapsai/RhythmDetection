//
//  RDRhythmView.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/28/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDRhythmView.h"

@interface RDRhythmView()
@property (strong, nonatomic) NSMutableArray *touchTimes;
@end

@implementation RDRhythmView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (nil != self)
    {
        self.touchTimes = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (nil != self)
    {
        self.touchTimes = [NSMutableArray array];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

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
