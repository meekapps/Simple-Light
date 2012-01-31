//
//  ViewController.h
//  Simple Light
//
//  Created by Mike Keller on 11/1/11.
//  Copyright (c) 2011 Meek Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController {
    
    AVCaptureDevice *captureDevice;
    AVCaptureSession *captureSession;
    
    BOOL mainOn;
    BOOL strobeOn;
    NSTimer *strobeTimer;
    float strobeDuration;
    UIImageView *batteryIndicator;
    UIImageView *calloutView;
    UIButton *strobeButton;
    UIButton *toggleButton;
    UIButton *brightnessButton;
    UIView *darknessOverlay;
}
@property (nonatomic, retain) AVCaptureDevice *captureDevice;
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic) BOOL mainOn;
@property (nonatomic) BOOL strobeOn;
@property (nonatomic, retain) NSTimer *strobeTimer;
@property (nonatomic) float strobeDuration;
@property (nonatomic, retain) UIImageView *batteryIndicator;
@property (nonatomic, retain) UIImageView *calloutView;
@property (nonatomic, retain) UIButton *strobeButton;
@property (nonatomic, retain) UIButton *toggleButton;
@property (nonatomic, retain) UIButton *brightnessButton;
@property (nonatomic, retain) UIView *darknessOverlay;

- (void) setBatteryLevel;
- (void) becameActive;

@end
