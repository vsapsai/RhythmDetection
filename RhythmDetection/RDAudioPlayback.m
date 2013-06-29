//
//  RDAudioPlayback.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAudioPlayback.h"
#import "RDAudioException.h"

@interface RDAudioPlayback()
@property (assign, nonatomic) ExtAudioFileRef audioFileRef;
@end

static OSStatus ReadFileData(void *							inRefCon,
                             AudioUnitRenderActionFlags *	ioActionFlags,
                             const AudioTimeStamp *			inTimeStamp,
                             UInt32							inBusNumber,
                             UInt32							inNumberFrames,
                             AudioBufferList *				ioData)
{
    RDAudioPlayback *self = (__bridge RDAudioPlayback *)inRefCon;
    ExtAudioFileRef audioFileRef = self.audioFileRef;
    OSStatus err = ExtAudioFileRead(audioFileRef, &inNumberFrames, ioData);
    return err;
}

@implementation RDAudioPlayback

@synthesize audioFileRef = _audioFileRef;

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (nil != self)
    {
        _audioFileRef = NULL;
        RDThrowIfError(ExtAudioFileOpenURL((__bridge CFURLRef)url, &_audioFileRef), @"open file %@", url);
        AudioStreamBasicDescription fileFormat;
        UInt32 size = sizeof(fileFormat);
        RDThrowIfError(ExtAudioFileGetProperty(_audioFileRef, kExtAudioFileProperty_FileDataFormat, &size, &fileFormat), @"read file format");

        [self setupGraph];
        SInt64 framesCount = 0;
        size = sizeof(framesCount);
        RDThrowIfError(ExtAudioFileGetProperty(_audioFileRef, kExtAudioFileProperty_FileLengthFrames, &size, &framesCount), @"read frames count");

        Float64 secondsDuration = framesCount / fileFormat.mSampleRate;
        NSLog(@"seconds = %f", secondsDuration);
        NSInteger minutes = (long)(secondsDuration / 60);
        NSInteger seconds = (long)(secondsDuration - 60 * minutes);
        NSLog(@"duration = %ld:%02ld", (long)minutes, (long)seconds);
    }
    return self;
}

- (void)setupGraph
{
    RDThrowIfError(NewAUGraph(&_graph), @"create graph");
    RDThrowIfError(AUGraphOpen(_graph), @"open graph");

    AudioComponentDescription outDesc;
    outDesc.componentType = kAudioUnitType_Output;
	outDesc.componentSubType = kAudioUnitSubType_DefaultOutput;
	outDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
	outDesc.componentFlags = 0;
	outDesc.componentFlagsMask = 0;
    RDThrowIfError(AUGraphAddNode(_graph, &outDesc, &_outputNode), @"create output node");
    RDThrowIfError(AUGraphNodeInfo(_graph, _outputNode, NULL, &_outputUnit), @"get output unit");
    // Make file format compatible with output stream format.
    AudioStreamBasicDescription streamFormat;
    UInt32 size = sizeof(streamFormat);
    RDThrowIfError(AudioUnitGetProperty(_outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, &size), @"read output stream format");
#if 1
    RDThrowIfError(ExtAudioFileSetProperty(_audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(streamFormat), &streamFormat), @"set file client format suitable for output");
#else
    int nChannels = 1;
    AudioStreamBasicDescription simpleStreamFormat = {
        .mSampleRate = streamFormat.mSampleRate,
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = (kAudioFormatFlagsCanonical/* | kAudioFormatFlagIsNonInterleaved*/),
        .mChannelsPerFrame = nChannels,
        .mFramesPerPacket = 1,
        .mBitsPerChannel = 8 * sizeof(AudioUnitSampleType),
        .mBytesPerPacket = nChannels * sizeof(AudioUnitSampleType),
        .mBytesPerFrame = nChannels * sizeof(AudioUnitSampleType)
    };
    RDThrowIfError(ExtAudioFileSetProperty(_audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(simpleStreamFormat), &simpleStreamFormat), @"set file client format suitable for output");
    RDThrowIfError(AudioUnitSetProperty(_outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &simpleStreamFormat, sizeof(simpleStreamFormat)), @"");
#endif

    // Setup data-providing callback.
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = ReadFileData;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    RDThrowIfError(AUGraphSetNodeInputCallback(_graph, _outputNode, 0, &callbackStruct), @"set input callback");
    //RDThrowIfError(AudioUnitSetProperty(_outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct)), @"set render callback");

    RDThrowIfError(AUGraphInitialize(_graph), @"initialize graph");
}

- (void)dealloc
{
    if (NULL != _audioFileRef)
    {
        RDThrowIfError(AUGraphUninitialize(_graph), @"uninitialize graph");
        RDThrowIfError(AUGraphClose(_graph), @"close graph");
        RDThrowIfError(DisposeAUGraph(_graph), @"dispose graph");
        RDThrowIfError(ExtAudioFileDispose(_audioFileRef), @"dispose file");
        _audioFileRef = NULL;
    }
}

#pragma mark -

- (void)start
{
    RDThrowIfError(AUGraphStart(_graph), @"start graph");
}

- (void)stop
{
    RDThrowIfError(AUGraphStop(_graph), @"stop graph");
}

@end
