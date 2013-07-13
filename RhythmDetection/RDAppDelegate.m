//
//  RDAppDelegate.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAppDelegate.h"
#import "RDProcessingController.h"

static NSString *const kRDLastOpenedFileKey = @"kRDLastOpenedFileKey";  // NSURL

@implementation RDAppDelegate

- (void)openAudioFileAtURL:(NSURL *)fileUrl
{
    NSParameterAssert(nil != fileUrl);
    [self.processingController loadFileAtURL:fileUrl];
    // vsapsai: it is better to wait until file is successfully loaded,  but I'm
    // fine with current subpar behavior.
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:fileUrl];
    [[NSUserDefaults standardUserDefaults] setURL:fileUrl forKey:kRDLastOpenedFileKey];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSURL *lastFileUrl = [[NSUserDefaults standardUserDefaults] URLForKey:kRDLastOpenedFileKey];
    if (nil != lastFileUrl)
    {
        [self openAudioFileAtURL:lastFileUrl];
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSURL *fileUrl = [NSURL fileURLWithPath:filename isDirectory:NO];
    [self openAudioFileAtURL:fileUrl];
    return YES;
}

- (IBAction)openDocument:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
    {
        if (NSFileHandlingPanelOKButton == result)
        {
            NSURL *fileUrl = [[openPanel URLs] lastObject];
            [self openAudioFileAtURL:fileUrl];
        }
    }];
}

@end
