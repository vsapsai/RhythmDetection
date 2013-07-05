//
//  RDAppDelegate.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RDProcessingController;

@interface RDAppDelegate : NSObject <NSApplicationDelegate>
@property (weak, nonatomic) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet RDProcessingController *processingController;
@end
