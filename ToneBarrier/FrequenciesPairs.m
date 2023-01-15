//
//  FrequenciesScore.m
//  
//
//  Created by Xcode Developer on 1/18/20.
//

// TO-DO: Create a separate object (class or method) for frequency pairs and add a duration property and an array for two Frequencies objects
//        --- OR --- Add duration property to Frequencies class
//        Rename this class as an aggregate of frequency pairs (a score)

#import "FrequenciesPairs.h"

@implementation FrequenciesPairs

// • takes the "old" frequencies object as a parameter and swaps the fade but keeps the original channel property value
// • creates a new frequency (the channel property of the new frequency is opposite of the old channel property value; always fade-in)
// • Passes the new frequency to itself (recursion)
// • Plays the frequencies parameter first (always fade-out)
// • Plays the new frequency second
// • Creates a series of four frequency objects, an old and new (calls completion block based on a count or limit parameter)
// • Returns two frequencies pairs (separate nodes, same schedule)

static const float high_frequency = 4000.0f;
static const float low_frequency = 500.0f;

NSArray<Frequencies *> * (^pairFrequencies)(Frequencies *) = ^NSArray<Frequencies *> * (Frequencies *returnFrequencies)
{
    StereoChannel returnFrequenciesStereoChannel = (StereoChannel)returnFrequencies.channel.unsignedIntValue;
    [returnFrequencies setChannel:(returnFrequenciesStereoChannel != StereoChannelLeft) ? @(StereoChannelLeft) : @(StereoChannelRight)];
    
    NSMutableArray *pairs = [NSMutableArray new];
    [pairs addObject:(returnFrequencies) ? returnFrequencies : [[Frequencies alloc] initWithFrequency1:(returnFrequencies.frequency1) ? returnFrequencies.frequency1.doubleValue : (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency) frequency2:(returnFrequencies.frequency1) ? returnFrequencies.frequency1.doubleValue : (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency) stereoChannel:(StereoChannel)returnFrequencies.channel.unsignedIntValue]];
    [pairs addObject:[[Frequencies alloc] initWithFrequency1:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency) frequency2:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency) stereoChannel:returnFrequenciesStereoChannel]];
    
    return (NSArray *)pairs;
};

NSArray<NSArray<Frequencies *> *> *(^scoreFrequenciesPairs)(void) = ^NSArray<NSArray<Frequencies *> *> *(void)
{
    __block NSMutableArray *score = [NSMutableArray new];
    
    static void (^block)(Frequencies *);
    block = ^void(Frequencies *returnFrequencies)
    {
        NSArray *frequenciesPair = pairFrequencies(returnFrequencies);
        [score addObject:frequenciesPair];
        if (score.count < 90) block([frequenciesPair lastObject]);
    };
    block(nil);
    
    return score;
};

- (instancetype)init
{
    return scoreFrequenciesPairs();
}

- (NSUInteger)count
{
    return 90;
}

- (NSArray<Frequencies *> *)objectAtIndex:(NSUInteger)index
{
    return (NSArray<Frequencies *> *)[self objectAtIndex:index];
}

@end
