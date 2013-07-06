//
//  RDAudioPlayback.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/25/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAudioPlayback.h"
#import "RDAudioException.h"
#import "RDAudioFile.h"
#import "RDBufferList.h"

//TODO: clarify difference between AudioSampleType and AudioUnitSampleType

@interface RDAudioPlayback()
@property (strong, nonatomic) RDBufferList *fileBufferList;
@property (assign, nonatomic) AudioConverterRef audioConverterRef;

@property (assign, nonatomic) SInt64 framesCount;
@property (assign, nonatomic) SInt64 frameIndex;

@property (assign, nonatomic, getter=isPlaying) BOOL playing;

- (OSStatus)readDataOfLength:(UInt32)framesCount inBufferList:(AudioBufferList *)bufferList;
@end

static OSStatus ReadFileData(void *							inRefCon,
                             AudioUnitRenderActionFlags *	ioActionFlags,
                             const AudioTimeStamp *			inTimeStamp,
                             UInt32							inBusNumber,
                             UInt32							inNumberFrames,
                             AudioBufferList *				ioData)
{
    RDAudioPlayback *self = (__bridge RDAudioPlayback *)inRefCon;
    OSStatus err = [self readDataOfLength:inNumberFrames inBufferList:ioData];
    return err;
}

//vsapsai: I've tried to silence buffer 0 - left channel is silent, buffer 1 -
// right channel is silent.
static OSStatus SilenceBuffer(void *							inRefCon,
                              AudioUnitRenderActionFlags *      ioActionFlags,
                              const AudioTimeStamp *			inTimeStamp,
                              UInt32							inBusNumber,
                              UInt32							inNumberFrames,
                              AudioBufferList *                 ioData)
{
    RDAudioPlayback *self = (__bridge RDAudioPlayback *)inRefCon;
    OSStatus err = [self readDataOfLength:inNumberFrames inBufferList:ioData];
    if (noErr == err)
    {
        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
    }
    return err;
}

static OSStatus AbsValue(void *							inRefCon,
                         AudioUnitRenderActionFlags *	ioActionFlags,
                         const AudioTimeStamp *			inTimeStamp,
                         UInt32							inBusNumber,
                         UInt32							inNumberFrames,
                         AudioBufferList *				ioData)
{
    RDAudioPlayback *self = (__bridge RDAudioPlayback *)inRefCon;
    OSStatus err = [self readDataOfLength:inNumberFrames inBufferList:ioData];
    if (noErr == err)
    {
        for (int bufferIndex = 0; bufferIndex < ioData->mNumberBuffers; bufferIndex++)
        {
            AudioSampleType *samples = ioData->mBuffers[bufferIndex].mData;
            NSUInteger samplesCount = ioData->mBuffers[bufferIndex].mDataByteSize / sizeof(AudioSampleType);
            for (NSUInteger i = 0; i < samplesCount; i++)
            {
                // Sounds awful, but can recognize.
                samples[i] = fabsf(samples[i]);

                // Cannot hear the difference.
                //samples[i] = -samples[i];
            }
        }
    }
    return err;
}

@implementation RDAudioPlayback

- (id)initWithAudioFile:(RDAudioFile *)audioFile
{
    self = [super init];
    if (nil != self)
    {
        [self setupGraph];
        [self setupConverter];
        self.fileBufferList = [self readAudioFileContent:audioFile];
        self.frameIndex = 0;
        self.framesCount = audioFile.framesCount;
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
    AUNode outputNode;
    RDThrowIfError(AUGraphAddNode(_graph, &outDesc, &outputNode), @"create output node");
    RDThrowIfError(AUGraphNodeInfo(_graph, outputNode, NULL, &_outputUnit), @"get output unit");

    // Setup data-providing callback.
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = ReadFileData;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    RDThrowIfError(AUGraphSetNodeInputCallback(_graph, outputNode, 0, &callbackStruct), @"set input callback");
    //RDThrowIfError(AudioUnitSetProperty(_outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct)), @"set render callback");

    RDThrowIfError(AUGraphInitialize(_graph), @"initialize graph");
}

- (void)setupConverter
{
    NSAssert(NULL != _graph, @"Need to setupGraph before setting up converter");
    AudioConverterRef audioConverterRef = NULL;
    AudioStreamBasicDescription outputFormat = [self outputDataFormat];
    AudioStreamBasicDescription internalBufferFormat = [self internalBufferDataFormat];
    RDThrowIfError(AudioConverterNew(&internalBufferFormat, &outputFormat, &audioConverterRef), @"create audio converter");
    self.audioConverterRef = audioConverterRef;
}

- (AudioStreamBasicDescription)outputDataFormat
{
    NSAssert(NULL != _graph, @"Need to setupGraph before getting output data format");
    AudioStreamBasicDescription outputFormat;
    UInt32 size = sizeof(outputFormat);
    RDThrowIfError(AudioUnitGetProperty(_outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outputFormat, &size), @"read output stream format");
    return outputFormat;
}

- (AudioStreamBasicDescription)internalBufferDataFormat
{
    AudioStreamBasicDescription internalBufferFormat = {
        .mSampleRate = [self outputDataFormat].mSampleRate,
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = (kAudioFormatFlagsCanonical | kAudioFormatFlagIsNonInterleaved),
        .mChannelsPerFrame = 2,
        .mFramesPerPacket = 1,
        .mBitsPerChannel = 8 * sizeof(AudioUnitSampleType),
        .mBytesPerPacket = sizeof(AudioUnitSampleType),
        .mBytesPerFrame = sizeof(AudioUnitSampleType)
    };
    return internalBufferFormat;
}

- (RDBufferList *)readAudioFileContent:(RDAudioFile *)audioFile
{
    SInt64 framesCount = [audioFile framesCount];
    NSAssert(framesCount <= UINT32_MAX, @"Subsequent computations shouldn't overflow 64 bits");
    SInt64 bufferSize64 = framesCount * sizeof(AudioUnitSampleType);
    NSAssert(bufferSize64 <= UINT32_MAX, @"Data size overflowing 32 bits isn't supported");
    UInt32 bufferSize = (UInt32)bufferSize64;
    RDBufferList *bufferList = [[RDBufferList alloc] initWithBufferSize:bufferSize count:2];
    [audioFile readDataInFormat:[self internalBufferDataFormat] inBufferList:bufferList];
    return bufferList;
}

- (void)dealloc
{
    if (NULL != _graph)
    {
        RDThrowIfError(AUGraphUninitialize(_graph), @"uninitialize graph");
        RDThrowIfError(AUGraphClose(_graph), @"close graph");
        RDThrowIfError(DisposeAUGraph(_graph), @"dispose graph");
        _graph = NULL;
    }
    if (NULL != _audioConverterRef)
    {
        RDThrowIfError(AudioConverterDispose(_audioConverterRef), @"dispose converter");
        _audioConverterRef = NULL;
    }
}

#pragma mark -

- (void)start
{
    if (!self.playing)
    {
        RDThrowIfError(AUGraphStart(_graph), @"start graph");
        self.playing = YES;
    }
}

- (void)stop
{
    if (self.playing)
    {
        RDThrowIfError(AUGraphStop(_graph), @"stop graph");
        self.playing = NO;
    }
}

#pragma mark -

- (OSStatus)readDataOfLength:(UInt32)framesCount inBufferList:(AudioBufferList *)bufferList
{
    OSStatus error = noErr;
    @autoreleasepool
    {
        SInt64 frameIndex = self.frameIndex;
        NSUInteger dataIndex = frameIndex * sizeof(AudioUnitSampleType);
        AudioBufferList *internalBufferList = [self.fileBufferList audioBufferListWithRange:NSMakeRange(dataIndex, framesCount * sizeof(AudioUnitSampleType))];
        error = AudioConverterConvertComplexBuffer(_audioConverterRef, framesCount, internalBufferList, bufferList);
    }
    if (noErr == error)
    {
        [self didPlayFrames:framesCount];
    }
    return error;
}

- (void)didPlayFrames:(UInt32)framesCount
{
    OSAtomicAdd64(framesCount, &_frameIndex);
}

- (float)currentProgress
{
    return (float)self.frameIndex / self.framesCount;
}

- (void)setCurrentProgress:(float)progress
{
    NSParameterAssert((0.0 <= progress) && (progress <= 1.0));
    _frameIndex = progress * self.framesCount;
}

@end
