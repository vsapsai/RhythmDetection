//
//  RDDataSimilarityDetector.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 7/26/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDDataSimilarityDetector : NSObject
- (id)initWithLength:(NSUInteger)length;

- (float)similarityMeasureBetweenData:(NSData *)data1 andData:(NSData *)data2;
@end
