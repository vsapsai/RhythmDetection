//
//  RDAudioEffect.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/15/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAudioEffect.h"
#import <AudioUnit/AudioUnit.h>
#import "RDAudioException.h"
#import "RDBufferList.h"
#include <mach/mach_time.h>

@interface RDAudioEffect()
@property (assign, nonatomic) AudioUnit audioUnit;
@property (strong, nonatomic) RDBufferList *sourceBufferList;
@property (assign, nonatomic) SInt64 frameIndex;

- (OSStatus)readDataOfLength:(UInt32)framesCount inBufferList:(AudioBufferList *)bufferList;
@end

static OSStatus ReadAudioData(void *							inRefCon,
                              AudioUnitRenderActionFlags *      ioActionFlags,
                              const AudioTimeStamp *			inTimeStamp,
                              UInt32							inBusNumber,
                              UInt32							inNumberFrames,
                              AudioBufferList *                 ioData)
{
    RDAudioEffect *self = (__bridge RDAudioEffect *)inRefCon;
    return [self readDataOfLength:inNumberFrames inBufferList:ioData];
}

@implementation RDAudioEffect

+ (id)lowPassFilterWithCutoffFrequency:(float)cutoffFrequency
{
    RDAudioEffect *effect = [[self alloc] initWithAudioUnitSubType:kAudioUnitSubType_LowPassFilter];
    AudioUnitParameterValue cutoffFrequencyValue = (AudioUnitParameterValue)cutoffFrequency;
    RDThrowIfError(AudioUnitSetParameter(effect.audioUnit, kLowPassParam_CutoffFrequency, kAudioUnitScope_Global, 0, cutoffFrequencyValue, 0), @"set low pass cutoff frequency");
    return effect;
}

- (id)initWithAudioUnitSubType:(OSType)audioUnitSubType
{
    self = [super init];
    if (nil != self)
    {
        AudioComponentDescription effectDescription =
        {
            .componentType = kAudioUnitType_Effect,
            .componentSubType = audioUnitSubType,
            .componentManufacturer = kAudioUnitManufacturer_Apple,
            .componentFlags = 0,
            .componentFlagsMask = 0
        };
        AudioUnit audioEffectUnit = [self createAudioUnitFromDescription:effectDescription];
        self.audioUnit = audioEffectUnit;
        if (NULL == audioEffectUnit)
        {
            self = nil;
        }
    }
    return self;
}

- (AudioUnit)createAudioUnitFromDescription:(AudioComponentDescription)audioComponentDescription
{
    AudioUnit audioUnit = NULL;
    AudioComponent audioComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
    if (NULL != audioComponent)
    {
        RDThrowIfError(AudioComponentInstanceNew(audioComponent, &audioUnit), @"new audio component instance");
        RDThrowIfError(AudioUnitInitialize(audioUnit), @"initialize audio unit");
    }
    return audioUnit;
}

- (void)dealloc
{
    if (NULL != self.audioUnit)
    {
        RDThrowIfError(AudioUnitUninitialize(self.audioUnit), @"uninitialize audio unit");
        RDThrowIfError(AudioComponentInstanceDispose(self.audioUnit), @"dispose audio component instance");
        self.audioUnit = NULL;
    }
}

#pragma mark -

- (UInt32)maxFramesPerSlice
{
    UInt32 framesPerSlice = 0;
    UInt32 size = sizeof(framesPerSlice);
    RDThrowIfError(AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &framesPerSlice, &size), @"read audio unit property");
    return framesPerSlice;
}

- (RDBufferList *)processBufferList:(RDBufferList *)bufferList
{
    NSParameterAssert(([bufferList buffersCount] > 0) && ([bufferList bufferSize] > 0));
    RDBufferList *result = [bufferList sameSizeBufferList];

    // Setup data-providing callback.
    self.sourceBufferList = bufferList;
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = ReadAudioData;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    RDThrowIfError(AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct)), @"set render callback");

    // Render data with audio unit.
    AudioUnitRenderActionFlags actionFlags = 0;
    AudioTimeStamp timeStamp;
    memset(&timeStamp, 0, sizeof(timeStamp));
    timeStamp.mSampleTime = 0;
    timeStamp.mHostTime = mach_absolute_time();
    timeStamp.mFlags = kAudioTimeStampSampleHostTimeValid;

    UInt32 framesCount = [bufferList bufferSize32] / sizeof(AudioUnitSampleType);
    UInt32 framesPerSlice = [self maxFramesPerSlice];
    self.frameIndex = 0;
    UInt32 frameIndex = 0;
    while (frameIndex < framesCount)
    {
        timeStamp.mSampleTime = frameIndex;
        timeStamp.mHostTime = mach_absolute_time();
        UInt32 sliceLength = MIN(framesPerSlice, framesCount - frameIndex);
        AudioBufferList *audioBufferList = [result audioBufferListWithRange:NSMakeRange(frameIndex * sizeof(AudioUnitSampleType), sliceLength * sizeof(AudioUnitSampleType))];
        RDThrowIfError(AudioUnitRender(self.audioUnit, &actionFlags, &timeStamp, 0/* inOutputBusNumber */, sliceLength, audioBufferList), @"render audio unit");
        frameIndex += sliceLength;
    }
    return result;
}

- (OSStatus)readDataOfLength:(UInt32)framesCount inBufferList:(AudioBufferList *)bufferList
{
    OSStatus error = noErr;
    @autoreleasepool
    {
        SInt64 frameIndex = self.frameIndex;
        NSUInteger dataIndex = frameIndex * sizeof(AudioUnitSampleType);
        NSUInteger dataLength = framesCount * sizeof(AudioUnitSampleType);
        AudioBufferList *internalBufferList = [self.sourceBufferList audioBufferListWithRange:NSMakeRange(dataIndex, dataLength)];
        NSAssert(bufferList->mNumberBuffers == internalBufferList->mNumberBuffers, @"mNumberBuffers mismatch");
        for (NSInteger i = 0; i < bufferList->mNumberBuffers; i++)
        {
            NSAssert(bufferList->mBuffers[i].mNumberChannels == internalBufferList->mBuffers[i].mNumberChannels, @"mNumberChannels mismatch in buffer #%ld", (long)i);
            NSAssert(bufferList->mBuffers[i].mDataByteSize <= internalBufferList->mBuffers[i].mDataByteSize, @"Buffer #%ld is too little, need %u bytes", (long)i, (unsigned int)internalBufferList->mBuffers[i].mDataByteSize);
            memcpy(bufferList->mBuffers[i].mData, internalBufferList->mBuffers[i].mData, internalBufferList->mBuffers[i].mDataByteSize);
        }
    }
    self.frameIndex += framesCount;
    return error;
}

@end
