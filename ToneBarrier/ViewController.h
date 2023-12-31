//
//  ViewController.h
//  ToneBarrier
//
//  Created by James Alan Bush on 6/15/22.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "AppDelegate.h"
#import "ToneGenerator.h"

#define low_bound   300.0f
#define high_bound 4000.0f

#define min_duration 0.25f
#define max_duration 1.75f

#define min_amplitude 0.5f
#define max_amplitude 1.0f

@interface ViewController : UIViewController <AVRoutePickerViewDelegate, DeviceStatusInterfaceDelegate>

@property (strong, nonatomic) UIDevice * _Nullable device;

@end
