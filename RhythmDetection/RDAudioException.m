//
//  RDAudioException.m
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import "RDAudioException.h"
#import <AudioToolbox/AudioToolbox.h>

NSString *const RDAudioExceptionName = @"RDAudioException";

void RDPrintAudioConverterErrorCodes()
{
#define PRINT_CONSTANT(c) NSLog(@"%s = %d", #c, c)
    PRINT_CONSTANT(kAudioConverterErr_FormatNotSupported);
    PRINT_CONSTANT(kAudioConverterErr_OperationNotSupported);
    PRINT_CONSTANT(kAudioConverterErr_PropertyNotSupported);
    PRINT_CONSTANT(kAudioConverterErr_InvalidInputSize);
    PRINT_CONSTANT(kAudioConverterErr_InvalidOutputSize);
    PRINT_CONSTANT(kAudioConverterErr_UnspecifiedError);
    PRINT_CONSTANT(kAudioConverterErr_BadPropertySizeError);
    PRINT_CONSTANT(kAudioConverterErr_RequiresPacketDescriptionsError);
    PRINT_CONSTANT(kAudioConverterErr_InputSampleRateOutOfRange);
    PRINT_CONSTANT(kAudioConverterErr_OutputSampleRateOutOfRange);
#undef PRINT_CONSTANT
}
