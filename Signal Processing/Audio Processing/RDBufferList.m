//
//  RDBufferList.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/4/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDBufferList.h"

@interface RDBufferList()
@property (strong, nonatomic) NSArray *buffers;
// Instead of allocating AudioBufferList every time one is requested, use
// `cachedAudioBufferList`.
@property (assign, nonatomic) AudioBufferList *cachedAudioBufferList;
@end

@implementation RDBufferList

- (id)initWithBuffers:(NSArray *)buffers
{
    NSParameterAssert([buffers count] > 0);
    NSUInteger bufferSize = [buffers[0] length];
    for (NSData *buffer in buffers)
    {
        NSParameterAssert([buffer length] == bufferSize);
    }
    self = [super init];
    if (nil != self)
    {
        self.buffers = [buffers copy];  // shallow copying on purpose
        self.cachedAudioBufferList = [self createEmptyAudioBufferList:[buffers count]];
    }
    return self;
}

- (id)initWithBufferSize:(UInt32)bufferByteSize count:(UInt32)buffersCount
{
    NSMutableArray *buffers = [NSMutableArray arrayWithCapacity:buffersCount];
    for (NSUInteger i = 0; i < buffersCount; i++)
    {
        [buffers addObject:[NSMutableData dataWithLength:bufferByteSize]];
    }
    return [self initWithBuffers:buffers];
}

- (void)dealloc
{
    free(self.cachedAudioBufferList);
    self.cachedAudioBufferList = NULL;
}

- (AudioBufferList *)createEmptyAudioBufferList:(UInt32)buffersCount
{
    AudioBufferList *bufferList = (AudioBufferList *)calloc(1, sizeof(AudioBufferList) + (buffersCount - 1) * sizeof(AudioBuffer));
    if (NULL != bufferList)
    {
        bufferList->mNumberBuffers = buffersCount;
        for (UInt32 i = 0; i < buffersCount; i++)
        {
            bufferList->mBuffers[i].mNumberChannels = 1;
            bufferList->mBuffers[i].mDataByteSize = 0;
            bufferList->mBuffers[i].mData = NULL;
        }
    }
    return bufferList;
}

- (RDBufferList *)sameSizeBufferList
{
    return [[RDBufferList alloc] initWithBufferSize:[self bufferSize32] count:[self buffersCount32]];
}

#pragma mark -

- (NSUInteger)buffersCount
{
    return [self.buffers count];
}

- (UInt32)buffersCount32
{
    NSUInteger count = [self buffersCount];
    NSAssert(count <= UINT32_MAX, @"buffersCount overflows UInt32");
    return (UInt32)count;
}

- (NSUInteger)bufferSize
{
    return [self.buffers[0] length];
}

- (UInt32)bufferSize32
{
    NSUInteger size = [self bufferSize];
    NSAssert(size <= UINT32_MAX, @"bufferSize overflows UInt32");
    return (UInt32)size;
}

- (AudioBufferList *)audioBufferList
{
    return [self audioBufferListWithRange:NSMakeRange(0, [self bufferSize])];
}

- (AudioBufferList *)audioBufferListWithRange:(NSRange)range
{
    NSParameterAssert(NSMaxRange(range) <= [self bufferSize]);
    AudioBufferList *bufferList = self.cachedAudioBufferList;
    [self.buffers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSMutableData *data = obj;
        NSAssert(range.length <= UINT32_MAX, @"Overflow UInt32");
        bufferList->mBuffers[idx].mDataByteSize = (UInt32)range.length;
        bufferList->mBuffers[idx].mData = ([data mutableBytes] + range.location);
    }];
    return bufferList;
}

@end
