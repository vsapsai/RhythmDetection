//
//  RDAudioFile.h
//  RhythmDetection
//
//  Created by Volodymyr Sapsai on 6/30/13.
//  Copyright (c) 2013 Volodymyr Sapsai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDAudioFile : NSObject
- (id)initWithURL:(NSURL *)url;

- (NSData *)PCMRepresentation;
@end
