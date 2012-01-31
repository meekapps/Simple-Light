//
//  ViewController.m
//  Simple Light
//
//  Created by Mike Keller on 11/1/11.
//  Copyright (c) 2011 Meek Apps. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

#define kStrobeMin 0.01
#define kStrobeMax 1.0

@implementation ViewController
@synthesize strobeTimer, mainOn, strobeOn, strobeDuration, batteryIndicator, calloutView, strobeButton, toggleButton, darknessOverlay, brightnessButton;
@synthesize captureSession, captureDevice;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Actions

- (void) changeBrightness: (NSNumber*)brightness {
    [[UIScreen mainScreen] setBrightness:[brightness floatValue]];
}

//User taps brightness button, lower it by increment until it's dark, then bring brightness to max.
- (void) brightnessAction:(id)sender {
    UIButton *button = (UIButton*)sender;
    NSInteger currentDarkness = button.tag;
    
    if (currentDarkness >= 3) {
        currentDarkness = 0;
    } else {
        currentDarkness++;
    }
    
    float newBrightness = 1 - (currentDarkness * 0.33f);
    float oldBrightness = [[UIScreen mainScreen] brightness];
    
    //Get brighter
    if (newBrightness > oldBrightness) {
        //animate the brightness
        for (float i = oldBrightness; i <= newBrightness; i+=0.03f) {        
            NSNumber *brightnessNumber = [NSNumber numberWithFloat:i];
            [self performSelector:@selector(changeBrightness:) withObject:brightnessNumber afterDelay:0.3f * (oldBrightness - i)];
        }
        
    //Get dimmer
    } else {
        //animate the dimming
        for (float i = oldBrightness; i >= newBrightness; i-=0.03f) {
            NSNumber *brightnessNumber = [NSNumber numberWithFloat:i];
            [self performSelector:@selector(changeBrightness:) withObject:brightnessNumber afterDelay:0.3f * (oldBrightness - i )];
        }
    }

    button.tag = currentDarkness;
}

//Main button, toggle light on and off
- (void) toggleOnOff:(id)sender {
    UIButton *button = (UIButton*)sender;
    if (mainOn == YES) {
        [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
        
        [button setImage:[UIImage imageNamed:@"main-normal.png"] forState:UIControlStateNormal];
        mainOn = NO;
        
    } else {
        [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
        [button setImage:[UIImage imageNamed:@"main-pressed.png"] forState:UIControlStateNormal];
        mainOn = YES;
    }
}

//Turn the light on or off, depending on if it already on or not.
- (void) strobe:(id)sender {
    
    if (strobeOn && mainOn) {
        if (self.captureDevice.torchMode == AVCaptureTorchModeOn) {
            self.captureDevice.torchMode = AVCaptureTorchModeOff;
        } else {
            self.captureDevice.torchMode = AVCaptureTorchModeOn;
        }
    }
}

//Show the strobe slider callout (with bounce in animation)
- (void) showCallout {
    calloutView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    calloutView.hidden = NO;
    calloutView.alpha = 1.0f;
    
    [UIView animateWithDuration:0.2f 
                          delay:0.0f
                        options:UIViewAnimationCurveEaseIn
                     animations:^(void){calloutView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);}
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.1f 
                                               delay:0.0f
                                             options:UIViewAnimationCurveEaseOut
                                          animations:^(void){calloutView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);} 
                                          completion:^(BOOL finished){}];
                     }];
}


//Hide the strobe slider callout (with fade out animation)
- (void) hideCallout {
    calloutView.alpha = 1.0f;
    calloutView.hidden = NO;
    [UIView animateWithDuration:0.2f 
                          delay:0.0f
                        options:UIViewAnimationCurveEaseInOut
                     animations:^(void){calloutView.alpha = 0.0f;} 
                     completion:^(BOOL finished){calloutView.hidden = YES;}];
}

- (void) strobeOnOff:(id)sender {
    UIButton *button = (UIButton*)sender;
    
    if (!strobeOn) { //turn strobe on
        [self showCallout];
        strobeOn = YES;
        [button setImage:[UIImage imageNamed:@"strobe-pressed.png"] forState:UIControlStateNormal];
        
        strobeTimer = [NSTimer scheduledTimerWithTimeInterval:strobeDuration target:self selector:@selector(strobe:) userInfo:nil repeats:YES];
        
    } else { //turn strobe off
        strobeOn = NO;
        [self hideCallout];
        [button setImage:[UIImage imageNamed:@"strobe-normal.png"] forState:UIControlStateNormal];
        
        if ([strobeTimer isValid]) {
            [strobeTimer invalidate];
            strobeTimer = nil;
        }
        
        if (mainOn) {
            [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
        }
    }
}

//Callout Slider changed
- (void) changeStrobeDuration:(id)sender {
    UISlider *slider = (UISlider*)sender;
    strobeDuration = slider.value;
    if ([strobeTimer isValid]) {
        [strobeTimer invalidate];
        strobeTimer = nil;
        strobeTimer = [NSTimer scheduledTimerWithTimeInterval:strobeDuration target:self selector:@selector(strobe:) userInfo:nil repeats:YES];
    }
}

//Set the Battery Icon (NSTimer triggers every 10 seconds)
- (void) setBatteryLevel {
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    batteryLevel = fabsf(batteryLevel);
    
    //NSLog(@"set battery level: %f", batteryLevel);
    
    if (batteryLevel >= 0.875) {                                //full
        [batteryIndicator setImage:[UIImage imageNamed:@"battery-1.0.png"]];
    } else if (batteryLevel < 0.875 && batteryLevel >= 0.625) { //75%
        [batteryIndicator setImage:[UIImage imageNamed:@"battery-0.75.png"]];
    } else if (batteryLevel < 0.625 && batteryLevel >= 0.375) { //50%
        [batteryIndicator setImage:[UIImage imageNamed:@"battery-0.5.png"]];
    } else if (batteryLevel < 0.375 && batteryLevel >= 0.125) { //25%
        [batteryIndicator setImage:[UIImage imageNamed:@"battery-0.25.png"]];
    } else {                                                    //0%
        [batteryIndicator setImage:[UIImage imageNamed:@"battery-0.0.png"]];
    }
    
    
}

#pragma mark - Setup

//Set up the AV Capture Session
//  Even though we're not using the camera, this is necessary to access the camera flash
- (void) setupCaptureSession {
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [self.captureDevice lockForConfiguration:NULL];
    [self.captureDevice setFocusMode:AVCaptureFocusModeLocked];
    [self.captureDevice setExposureMode:AVCaptureExposureModeLocked];
    [self.captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
    
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:self.captureDevice 
										  error:nil];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [self.captureSession addInput:captureInput];
    [self.captureSession startRunning];
}

//Create the main controls overlay view with bounds of the entire view
- (UIView*) createOverlayView {
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    
    //Background
    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [overlay addSubview:bgView];
    
    //main on button
    toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [toggleButton setImage:[UIImage imageNamed:@"main-normal.png"] forState:UIControlStateNormal];
    [toggleButton setImage:[UIImage imageNamed:@"main-highlighted.png"] forState:UIControlStateHighlighted];
    mainOn = NO;
    toggleButton.alpha = 0.5f;
    [toggleButton setFrame:CGRectMake(77.0f, 40.0f, 166.0f, 166.0f)];
    [toggleButton addTarget:self action:@selector(toggleOnOff:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:toggleButton];
    
    //strobe button
    strobeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    strobeOn = NO;
    strobeButton.alpha = 0.5f;
    [strobeButton setFrame:CGRectMake(127.0f, 290.0f, 66.0f, 66.0f)];
    [strobeButton setImage:[UIImage imageNamed:@"strobe-normal.png"] forState:UIControlStateNormal];
    [strobeButton setImage:[UIImage imageNamed:@"strobe-highlighted.png"] forState:UIControlStateHighlighted];
    [strobeButton addTarget:self action:@selector(strobeOnOff:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:strobeButton];
    
    //Create the slider callout
    calloutView = [[UIImageView alloc] initWithFrame:CGRectMake(55.5f, 350.0f, 209.0f, 91.0f)];
    [calloutView setImage:[UIImage imageNamed:@"callout.png"]];
    calloutView.userInteractionEnabled = YES;
    calloutView.hidden = YES;
    
    //strobe button slider
    UISlider *strobeSlider = [[UISlider alloc] initWithFrame:CGRectMake(9.5f, 39.0f, 190.0f, 30.0f)];
    strobeSlider.minimumTrackTintColor = [UIColor darkGrayColor];
    strobeSlider.minimumValue = kStrobeMin;
    strobeSlider.maximumValue = kStrobeMax;
    strobeSlider.value = (kStrobeMax + kStrobeMin) / 2.0f;
    strobeDuration = strobeSlider.value;
    [strobeSlider addTarget:self action:@selector(changeStrobeDuration:) forControlEvents:UIControlEventValueChanged];
    
    [calloutView addSubview:strobeSlider];
    [overlay addSubview:calloutView];
    
    
    //battery life indicator
    batteryIndicator = [[UIImageView alloc] init];
    [batteryIndicator setFrame:CGRectMake(248.0f, 427.0f, 62.0f, 43.0f)];
    batteryIndicator.alpha = 0.5f;
    [self setBatteryLevel];
    [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(setBatteryLevel) userInfo:nil repeats:YES];
    [overlay addSubview:batteryIndicator];
    
    //top light
    UIImageView *lightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"light.png"]];
    [overlay addSubview:lightView];
    
    //darkness overlay
    darknessOverlay = [[UIView alloc] initWithFrame:overlay.frame];
    [darknessOverlay setBackgroundColor:[UIColor blackColor]];
    [darknessOverlay setTag:0];
    [darknessOverlay setUserInteractionEnabled:NO];
    [darknessOverlay setAlpha:0.0f];
    [overlay addSubview:darknessOverlay];
    
    //Brightness Button
    brightnessButton = [UIButton buttonWithType:UIButtonTypeCustom];
    brightnessButton.tag = 0;
    brightnessButton.alpha = 0.5f;
    [brightnessButton setFrame:CGRectMake(20.0f, 431.0f, 35.0f, 35.0f)];
    [brightnessButton setImage:[UIImage imageNamed:@"brightness-normal.png"] forState:UIControlStateNormal];
    [brightnessButton setImage:[UIImage imageNamed:@"brightness-pressed.png"] forState:UIControlStateHighlighted];
    [brightnessButton addTarget:self action:@selector(brightnessAction:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:brightnessButton];

    return overlay;
}

#pragma mark - Life cycle

- (void) becameActive {
    NSLog(@"active");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add observer that turns the light back on when returning to app (posted in applicationDidBecomeActive)
    [[NSNotificationCenter defaultCenter] addObserverForName:@"kAppBecameActive"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note){
                                                      if (mainOn) {
                                                          [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
                                                      }
                                                  }
     ];
    
    //Monitor battery levels
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];    
    
    //Set up the AV Capture Session - access to camera for use of light
    [self setupCaptureSession];

    //create the overlay view and set the view 
    self.view = [self createOverlayView];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Fade in the controls
    [UIView animateWithDuration:0.5f 
                          delay:0.0f
                        options:UIViewAnimationCurveEaseInOut
                     animations:^(void) {
                         toggleButton.alpha = 1.0f;
                         strobeButton.alpha = 1.0f;
                         batteryIndicator.alpha = 1.0f;
                         brightnessButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){}];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

@end
