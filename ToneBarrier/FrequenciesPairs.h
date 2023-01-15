//
//  FrequenciesPairs.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 1/18/20.
//  Copyright © 2020 The Life of a Demoniac. All rights reserved.
//

#ifndef FrequenciesPairs_h
#define FrequenciesPairs_h

#import <Foundation/Foundation.h>

#import "Frequencies.h"

NS_ASSUME_NONNULL_BEGIN

@interface FrequenciesPairs : NSArray

@property (readonly) NSUInteger count;
- (NSArray<Frequencies *> *)objectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

#endif /* FrequenciesPairs_h */
