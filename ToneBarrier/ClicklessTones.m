//
//  ClicklessTones.m
//  ToneBarrierBeta
//
//  Created by James Alan Bush on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ClicklessTones.h"
#include "easing.h"


static const double high_frequency = 1750.0;
static const double low_frequency  = 500.0;
static const double min_duration   = 0.25;
static const double max_duration   = 2.00;

@interface ClicklessTones ()
{
    double duration_bifurcate;
}

@property (nonatomic, readonly) GKMersenneTwisterRandomSource * _Nullable randomizer;
@property (nonatomic, readonly) GKGaussianDistribution * _Nullable distributor;

// Randomizes duration
@property (nonatomic, readonly) GKGaussianDistribution * _Nullable distributor_duration;

@end


@implementation ClicklessTones

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _randomizer  = [[GKMersenneTwisterRandomSource alloc] initWithSeed:time(NULL)];
        _distributor = [[GKGaussianDistribution alloc] initWithRandomSource:_randomizer mean:(high_frequency / .75) deviation:low_frequency];
        _distributor_duration = [[GKGaussianDistribution alloc] initWithRandomSource:_randomizer mean:max_duration deviation:min_duration];
    }
    
    return self;
}

static __inline__ double normalize(double unscaledNum, double minAllowed, double maxAllowed, double min, double max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}

static __inline__ double RandomDoubleBetween(double a, double b) {
    return a + (b - a) * ((double) random() / (double) RAND_MAX);
}

//- (float)generateRandomNumberBetweenMin:(int)min Max:(int)max
//{
//    return ( (arc4random() % (max-min+1)) + min );
//}

#define max_frequency      1500.0
#define min_frequency       100.0
#define max_trill_interval    3.0
#define min_trill_interval    1.0
#define duration_interval     5.0
#define duration_maximum      2.0


// Elements of an effective tone:
// High-pitched
// Modulating amplitude
// Alternating channel output
// Loud
// Non-natural (no spatialization)
//
// Elements of an effective score:
// Random frequencies
// Random duration
// Random tonality

// To-Do: Multiply the frequency by a random number between 1.01 and 1.1)

typedef NS_ENUM(NSUInteger, TonalHarmony) {
    TonalHarmonyConsonance,
    TonalHarmonyDissonance,
    TonalHarmonyRandom
};

typedef NS_ENUM(NSUInteger, TonalInterval) {
    TonalIntervalUnison,
    TonalIntervalOctave,
    TonalIntervalMajorSixth,
    TonalIntervalPerfectFifth,
    TonalIntervalPerfectFourth,
    TonalIntervalMajorThird,
    TonalIntervalMinorThird,
    TonalIntervalRandom
};

typedef NS_ENUM(NSUInteger, TonalEnvelope) {
    TonalEnvelopeAverageSustain,
    TonalEnvelopeLongSustain,
    TonalEnvelopeShortSustain
};

double Tonality(double frequency, TonalInterval interval, TonalHarmony harmony)
{
    double new_frequency = frequency;
    switch (harmony) {
        case TonalHarmonyDissonance:
            new_frequency *= (1.1 + drand48());
            break;
            
        case TonalHarmonyConsonance:
            new_frequency = Interval(frequency, interval);
            break;
            
        case TonalHarmonyRandom:
            new_frequency = Tonality(frequency, interval, (TonalHarmony)arc4random_uniform(2));
            break;
            
        default:
            break;
    }
    
    return new_frequency;
}

static __inline__ double Envelope(double x, TonalEnvelope envelope)
{
    double x_envelope = 1.0;
    switch (envelope) {
        case TonalEnvelopeAverageSustain:
            x_envelope = sinf(x * M_PI) * (sinf((2 * x * M_PI) / 2));
            break;
            
        case TonalEnvelopeLongSustain:
            x_envelope = sinf(x * M_PI) * -sinf(
                                                ((Envelope(x, TonalEnvelopeAverageSustain) - (2.0 * Envelope(x, TonalEnvelopeAverageSustain)))) / 2.0)
            * (M_PI / 2.0) * 2.0;
            break;
            
        case TonalEnvelopeShortSustain:
            x_envelope = sinf(x * M_PI) * -sinf(
                                                ((Envelope(x, TonalEnvelopeAverageSustain) - (-2.0 * Envelope(x, TonalEnvelopeAverageSustain)))) / 2.0)
            * (M_PI / 2.0) * 2.0;
            break;
            
        default:
            break;
    }
    
    return x_envelope;
}

typedef NS_ENUM(NSUInteger, TonalTrill) {
    TonalTrillUnsigned,
    TonalTrillInverse
};

static double(^Frequency)(double, double) = ^ double(double time, double frequency)
{
    return pow(sin(M_PI * time * frequency), 2.0);
};

static double(^TrillInterval)(double) = ^ double (double frequency) {
    return ((frequency / (max_frequency - min_frequency) * (max_trill_interval - min_trill_interval)) + min_trill_interval);
};

static double(^Trill)(double, double) = ^ double(double time, double trill)
{
    return pow(2.0 * pow(sin(M_PI * time * trill), 2.0) * 0.5, 4.0);
};

static double(^TrillInverse)(double, double) =  ^ double(double time, double trill)
{
    return pow(-(2.0 * pow(sin(M_PI * time * trill), 2.0) * 0.5) + 1.0, 4.0);
};

static double(^Amplitude)(double, double) = ^ double(double time, double frequency)
{
    return pow(sin(time * M_PI * frequency), 3.0);
};

static double(^Interval)(double, TonalInterval) = ^ double (double frequency, TonalInterval interval) {
    double new_frequency = frequency;
    switch (interval)
    {
        case TonalIntervalUnison:
            new_frequency *= 1.0;
            break;
            
        case TonalIntervalOctave:
            new_frequency *= 2.0;
            break;
            
        case TonalIntervalMajorSixth:
            new_frequency *= 5.0/3.0;
            break;
            
        case TonalIntervalPerfectFifth:
            new_frequency *= 4.0/3.0;
            break;
            
        case TonalIntervalMajorThird:
            new_frequency *= 5.0/4.0;
            break;
            
        case TonalIntervalMinorThird:
            new_frequency *= 6.0/5.0;
            break;
            
        case TonalIntervalRandom:
            new_frequency = Interval(frequency, (TonalInterval)arc4random_uniform(7));
            
        default:
            break;
    }
    
    return new_frequency;
};

static __inline__ double Normalize(double a, double b)
{
    return (double)(a / b);
}

- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    static AVAudioPCMBuffer * (^createAudioBuffer)(double);
    createAudioBuffer = ^AVAudioPCMBuffer * (double frequency) {
        AVAudioFrameCount frameCount = audioFormat.sampleRate * (audioFormat.channelCount / RandomDoubleBetween(2, 4));
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
        pcmBuffer.frameLength = frameCount;
        float *left_channel  = pcmBuffer.floatChannelData[0];
        float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : left_channel;
        
        double amplitude_frequency = arc4random_uniform(4) + 2;
        double harmonized_frequency = Tonality(frequency, TonalIntervalRandom, TonalHarmonyRandom);
        double trill_interval       = TrillInterval(harmonized_frequency);
        
        for (int index = 0; index < frameCount; index++)
        {
            double normalized_index = Normalize(index, frameCount);
            double trill            = Trill(normalized_index, trill_interval);
            double trill_inverse    = TrillInverse(normalized_index, trill_interval);
            double amplitude        = Amplitude(normalized_index, amplitude_frequency);
            left_channel[index]     = Frequency(normalized_index, frequency)  * amplitude * trill;
            right_channel[index]    = Frequency(normalized_index, harmonized_frequency) * amplitude * trill_inverse;
        }
        
        return pcmBuffer;
    };
    
    static void (^block)(void);
    block = ^{
        createAudioBufferCompletionBlock(createAudioBuffer([self->_distributor nextInt]), createAudioBuffer([self->_distributor nextInt]), ^{
            self->duration_bifurcate = [self->_distributor_duration nextInt];
            block();
        });
    };
    block();
}

@end
