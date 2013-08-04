//
//  RDViewController.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/28/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDRhythmView.h"

@interface RDViewController : UIViewController<RDRhythmViewDelegate>
@property (strong, nonatomic) IBOutlet RDRhythmView *rhythmView;
@end
