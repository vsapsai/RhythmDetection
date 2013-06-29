//
//  RDAudioException.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const RDAudioExceptionName;

#define RDThrowIfError(error, desc, ...) \
    do { \
        OSStatus __err = (error); \
        if (noErr != __err) { \
            [NSException raise:RDAudioExceptionName format:(desc), ##__VA_ARGS__]; \
        } \
    } while (0)
