//
//  RDAppDelegate.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RDAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;

@end
