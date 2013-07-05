//
//  RDAudioFile.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/30/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAudioFile.h"
#import <AudioToolbox/AudioToolbox.h>
#import "RDAudioException.h"
#import "RDBufferList.h"

@interface RDAudioFile()
{
@private
    ExtAudioFileRef _audioFileRef;
}
@end

@implementation RDAudioFile

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (nil != self)
    {
        _audioFileRef = NULL;
        RDThrowIfError(ExtAudioFileOpenURL((__bridge CFURLRef)url, &_audioFileRef), @"open file %@", url);
    }
    return self;
}

- (void)dealloc
{
    if (NULL != _audioFileRef)
    {
        RDThrowIfError(ExtAudioFileDispose(_audioFileRef), @"dispose file");
        _audioFileRef = NULL;
    }
}

#pragma mark -

- (AudioStreamBasicDescription)fileFormat
{
    AudioStreamBasicDescription fileFormat;
    UInt32 size = sizeof(fileFormat);
    RDThrowIfError(ExtAudioFileGetProperty(_audioFileRef, kExtAudioFileProperty_FileDataFormat, &size, &fileFormat), @"read file format");
    return fileFormat;
}

- (Float64)sampleRate
{
    return [self fileFormat].mSampleRate;
}

- (SInt64)framesCount
{
    SInt64 framesCount = 0;
    UInt32 size = sizeof(framesCount);
    RDThrowIfError(ExtAudioFileGetProperty(_audioFileRef, kExtAudioFileProperty_FileLengthFrames, &size, &framesCount), @"read frames count");
    return framesCount;
}

- (NSTimeInterval)duration
{
    return [self framesCount] / [self sampleRate];
}

- (void)readDataInFormat:(AudioStreamBasicDescription)dataFormat inBufferList:(RDBufferList *)bufferList
{
    RDThrowIfError(ExtAudioFileSetProperty(_audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(dataFormat), &dataFormat), @"set client data format for file");
    SInt64 framesCount64 = [self framesCount];
    NSAssert(framesCount64 <= UINT32_MAX, @"Data size overflowing 32 bits isn't supported");
    UInt32 framesCount = (UInt32)framesCount64;
    UInt32 readFramesCount = framesCount;
    RDThrowIfError(ExtAudioFileRead(_audioFileRef, &readFramesCount, [bufferList audioBufferList]), @"read file data");
    NSAssert(readFramesCount == framesCount, @"Not all file content is read");
}

//TODO: use readDataInFormat:...
- (NSData *)PCMRepresentation
{
    NSAssert(NULL != _audioFileRef, @"ExtAudioFileRef is absent");
    AudioStreamBasicDescription fileFormat = [self fileFormat];

    UInt32 nChannels = 1;
    AudioStreamBasicDescription monoPCMFormat = {
        .mSampleRate = fileFormat.mSampleRate,
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = kAudioFormatFlagsCanonical,
        .mChannelsPerFrame = nChannels,
        .mFramesPerPacket = 1,
        .mBitsPerChannel = 8 * sizeof(AudioUnitSampleType),
        .mBytesPerPacket = nChannels * sizeof(AudioUnitSampleType),
        .mBytesPerFrame = nChannels * sizeof(AudioUnitSampleType)
    };
    RDThrowIfError(ExtAudioFileSetProperty(_audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(monoPCMFormat), &monoPCMFormat), @"set client data format for file");

    SInt64 framesCount = [self framesCount];
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = nChannels;
    SInt64 samplesCount = framesCount * nChannels;
    NSAssert(samplesCount <= UINT32_MAX, @"Data size overflowing 32 bits isn't supported");
    UInt32 framesCount32 = (UInt32)framesCount;
    UInt32 samplesCount32 = (UInt32)samplesCount;
    bufferList.mBuffers[0].mData = calloc(samplesCount32, sizeof(AudioSampleType));
    bufferList.mBuffers[0].mDataByteSize = samplesCount32 * sizeof(AudioSampleType);
    RDThrowIfError(ExtAudioFileRead(_audioFileRef, &framesCount32, &bufferList), @"read data");
    return [NSData dataWithBytesNoCopy:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize freeWhenDone:YES];
}

@end
