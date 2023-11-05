//
//  ClicklessTones.m
//  ToneBarrierBeta
//
//  Created by James Alan Bush on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ClicklessTones.h"
#include "easing.h"


static const double high_frequency = 1500.0;
static const double low_frequency  = 100.0;
static const double min_duration   = 0.25;
static const double max_duration   = 1.75;

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

static AVAudioFramePosition frame = 0;
static AVAudioFramePosition * frame_t = &frame;
static simd_double1 n_time;
static simd_double1 * n_time_t = &n_time;

static typeof(simd_double1 *) normalized_times_ref = NULL;
static typeof(normalized_times_ref) (^normalized_times)(AVAudioFrameCount) = ^typeof(normalized_times_ref) (AVAudioFrameCount frame_count) {
    typedef simd_double1 normalized_time_type[frame_count];
    typeof(normalized_time_type) normalized_time;
    normalized_times_ref = &normalized_time[0];
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
    for (*frame_t = 0; *frame_t < frame_count; *frame_t += 1) {
        *(n_time_t) = 0.0 + ((((*frame_t - 0.0) * (1.0 - 0.0))) / (~-frame_count - 0.0));
        *(normalized_times_ref + *frame_t) = *(n_time_t);
    }
    
    return normalized_times_ref;
};

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

static __inline__ double Tonality(double frequency, TonalInterval interval, TonalHarmony harmony)
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
    return pow(sin(time * M_PI * frequency), 2.0);
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

static AVAudioFramePosition frame_index = 0;
static AVAudioFramePosition * frame_index_t = &frame_index;
static double gain_adjustment = 0;
typeof(gain_adjustment) * gain_adjustment_t = &gain_adjustment;
AVAudioPCMBuffer *pcmBuffer = nil;

- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    static AVAudioPCMBuffer * (^createAudioBuffer)(double);
    createAudioBuffer = ^AVAudioPCMBuffer * (double frequency) {
        AVAudioFrameCount frame_count = audioFormat.sampleRate * (audioFormat.channelCount / RandomDoubleBetween(2, 4));
        pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frame_count];
        pcmBuffer.frameLength = frame_count;
        float *left_channel  = pcmBuffer.floatChannelData[0];
        float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : left_channel;
        
        double amplitude_frequency  = arc4random_uniform(4) + 2;
        double harmonized_frequency = Tonality(frequency, TonalIntervalRandom, TonalHarmonyRandom);
        double trill_interval       = TrillInterval(harmonized_frequency);
        
        normalized_times(frame_count);
        
        for (*frame_t = 0; *frame_t < frame_count; *frame_t += 1) {
            *gain_adjustment_t = sin((*(normalized_times_ref + *frame_t) - 0.5) * M_PI);
//            NSLog(@"*gain_adjustment_t == %f\t\t%f", *gain_adjustment_t, *(normalized_times_ref + *frame_t));
            
            double trill            = Trill(*(normalized_times_ref + *frame_t), trill_interval);
            double trill_inverse    = TrillInverse(*(normalized_times_ref + *frame_t), trill_interval);
            double amplitude        = Amplitude(*(normalized_times_ref + *frame_t), amplitude_frequency);
            left_channel[*frame_t]  = /**gain_adjustment_t * */(Frequency(*(normalized_times_ref + *frame_t), frequency)            * amplitude * trill);
            right_channel[*frame_t] = /**gain_adjustment_t * */(Frequency(*(normalized_times_ref + *frame_t), harmonized_frequency) * amplitude * trill_inverse);
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

//typedef NS_ENUM(NSUInteger, Fade) {
//    FadeOut,
//    FadeIn
//};
//
//double (^fade)(Fade, double, double) = ^double(Fade fadeType, double x, double freq_amp)
//{
//    double fade_effect = freq_amp * ((fadeType == FadeIn) ? x : (1.0 - x));
//
//    return fade_effect;
//};
//
//#define M_PI_SQR M_PI * 2.f
//
//- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock {
//    static unsigned int fade_bit = 1;
//    static AVAudioPCMBuffer * (^createAudioBuffer)(Fade[2], simd_double2x2);
//    static simd_double2x2 thetas, theta_increments, samples;
//    createAudioBuffer = ^ AVAudioPCMBuffer * (Fade fades[2], simd_double2x2 frequencies) {
//        AVAudioFrameCount frameCount = audioFormat.sampleRate * 2;
//        AVAudioPCMBuffer * pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
//        pcmBuffer.frameLength = frameCount;
//        simd_double1 split_frame = (simd_double1)(frameCount * (RandomDoubleBetween(0.125f, 0.875f)));
//        simd_double2x2 phase_angular_units = simd_matrix_from_rows(simd_make_double2((simd_double1)(M_PI_SQR / split_frame), (simd_double1)(M_PI_SQR /
//                                                                                                                                            (frameCount - split_frame))),
//                                                                   simd_make_double2((simd_double1)(M_PI_SQR / (frameCount - split_frame)), (simd_double1)
//                                                                                     (M_PI_SQR / split_frame)));
//        theta_increments = matrix_multiply(phase_angular_units, frequencies);
//        // simd_double1 phase_angular_unit = (simd_double1)(M_PI_SQR / frameCount);
//        // theta_increments = matrix_scale(phase_angular_unit, frequencies);
//        simd_double2x2 durations = simd_matrix_from_rows(simd_make_double2(split_frame, frameCount - split_frame),
//                                                         simd_make_double2(frameCount - split_frame, split_frame));
//        for (AVAudioFrameCount frame = 0; frame < frameCount; frame++) {
//            // simd_double1 normalized_index = LinearInterpolation(frame, frameCount);
//            samples = simd_matrix_from_rows(_simd_sin_d2(simd_make_double2((simd_double2)thetas.columns[0])),
//                                            _simd_sin_d2(simd_make_double2((simd_double2)thetas.columns[1])));
//            simd_double2 a = simd_make_double2((simd_double2)(samples.columns[0]) * simd_make_double2((simd_double2)durations.columns[0]));
//            simd_double2 b = simd_make_double2((simd_double2)(samples.columns[1]) * simd_make_double2((simd_double2)durations.columns[1]));
//            simd_double2 ab_sum = _simd_sin_d2(a + b);
//            simd_double2 ab_sub = _simd_cos_d2(a - b);
//            simd_double2 ab_mul = ab_sum * ab_sub;
//            samples = simd_matrix_from_rows(simd_make_double2((simd_double2)((2.f * ab_mul) / 2.f) * simd_make_double2((simd_double2)durations.columns[1])),
//                                            simd_make_double2((simd_double2)((2.f * ab_mul) / 2.f) * simd_make_double2((simd_double2)durations.columns[0])));
//            thetas = simd_add(thetas, theta_increments);
//            for (AVAudioChannelCount channel_count = 0; channel_count < audioFormat.channelCount; channel_count++) {
//                pcmBuffer.floatChannelData[channel_count][frame] = samples.columns[channel_count][frame];
//                !(thetas.columns[channel_count ^ 1][channel_count] > M_PI_SQR) && (thetas.columns[channel_count ^ 1][channel_count] -= M_PI_SQR); //0 = 1 0 //1 = 0 1
//                !(thetas.columns[channel_count][channel_count ^ 1] > M_PI_SQR) && (thetas.columns[channel_count][channel_count ^ 1] -= M_PI_SQR); //0 = 0 1 //1 = 1 0
//            }
//        }
//        return pcmBuffer;
//    };
//
//    static void (^block)(void);
//    block = ^{
//        Fade fades[2][2] = {{({fade_bit ^= 1; }), fade_bit ^ 1}, {fade_bit, fade_bit ^ 1}};
//        createAudioBufferCompletionBlock(createAudioBuffer(fades[0], simd_matrix_from_rows(simd_make_double2([self->_distributor nextInt], [self->_distributor nextInt]), simd_make_double2([self->_distributor nextInt], [self->_distributor nextInt]))), //RandomFloatBetween(4, 6), RandomFloatBetween(4, 6))),
//                                         createAudioBuffer(fades[1], simd_matrix_from_rows(simd_make_double2([self->_distributor nextInt], [self->_distributor nextInt]), simd_make_double2([self->_distributor nextInt], [self->_distributor nextInt]))), //RandomFloatBetween(4, 6), RandomFloatBetween(4, 6))),
//                                         ^{
//            block();
//        });
//    };
//    block();
//}


@end
