//
//  RDRepeatedDataGenerator.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDRepeatedDataGenerator : NSObject
+ (NSData *)generateDataWithPattern:(NSData *)pattern samplingRate:(NSUInteger)samplingRate length:(NSUInteger)length;
+ (NSData *)generateDataWithPattern:(NSData *)pattern length:(NSUInteger)length;
@end
