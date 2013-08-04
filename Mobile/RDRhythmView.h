//
//  RDRhythmView.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/28/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RDRhythmViewDelegate;

@interface RDRhythmView : UIView
@property (assign, nonatomic) NSUInteger touchesCount;
@property (weak, nonatomic) IBOutlet id<RDRhythmViewDelegate> delegate;

- (void)startAnimationWithPeriod:(NSTimeInterval)animationPeriod startTime:(NSDate *)startTime;
- (void)stopAnimation;
@end

@protocol RDRhythmViewDelegate <NSObject>
- (void)rhythmView:(RDRhythmView *)view didReceiveTouchesAtTimes:(NSArray *)touchTimes;
@end
