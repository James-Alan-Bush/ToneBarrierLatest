//
//  ClicklessTones.h
//  ToneBarrierBeta
//
//  Created by James Alan Bush on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import <Accelerate/Accelerate.h>
#import "ToneGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface ClicklessTones : NSObject <ToneBarrierPlayerDelegate>

- (instancetype)init;
- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock;

@end

NS_ASSUME_NONNULL_END
