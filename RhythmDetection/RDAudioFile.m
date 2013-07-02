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

- (NSData *)PCMRepresentation
{
    NSAssert(NULL != _audioFileRef, @"ExtAudioFileRef is absent");
    AudioStreamBasicDescription fileFormat;
    UInt32 size = sizeof(fileFormat);
    RDThrowIfError(ExtAudioFileGetProperty(_audioFileRef, kExtAudioFileProperty_FileDataFormat, &size, &fileFormat), @"read file format");

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
    RDThrowIfError(ExtAudioFileSetProperty(_audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(monoPCMFormat), &monoPCMFormat), @"set suitable client data format");

    SInt64 framesCount = 0;
    size = sizeof(framesCount);
    RDThrowIfError(ExtAudioFileGetProperty(_audioFileRef, kExtAudioFileProperty_FileLengthFrames, &size, &framesCount), @"read frames count");
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = nChannels;
    SInt64 samplesCount = framesCount * nChannels;
    NSAssert(samplesCount <= (1LL << 32), @"Data size overflowing 32 bits isn't supported");
    UInt32 framesCount32 = (UInt32)framesCount;
    UInt32 samplesCount32 = (UInt32)samplesCount;
    bufferList.mBuffers[0].mData = calloc(samplesCount32, sizeof(AudioSampleType));
    bufferList.mBuffers[0].mDataByteSize = samplesCount32 * sizeof(AudioSampleType);
    RDThrowIfError(ExtAudioFileRead(_audioFileRef, &framesCount32, &bufferList), @"read data");
    return [NSData dataWithBytesNoCopy:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize freeWhenDone:YES];
}

@end
