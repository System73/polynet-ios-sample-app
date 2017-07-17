//
//  ViewController.m
//  PolyNetSampleObjectiveC
//
//  Created by System73.
//  Copyright © 2017 System73. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <PolyNetClient/PolyNetClient.h>

@interface ViewController () <S73PolyNetDelegate, S73PolyNetDataSource>

#pragma mark Properties

@property (nonatomic, nullable, strong) S73PolyNet * polyNet;
@property (nonatomic, nullable, strong) AVPlayerViewController * playerViewController;
@property (nonatomic, nullable, strong) AVPlayer * player;

#pragma mark IBOutlets

@property (weak, nonatomic) IBOutlet UITextField *manifestUrlTextField;
@property (weak, nonatomic) IBOutlet UITextField *channelIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *backendUrlTextField;
@property (weak, nonatomic) IBOutlet UITextField *stunServerUrlTextField;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation ViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Remove a previous polyNet instance
    if (self.polyNet) {
        [self.polyNet close];
        self.polyNet = nil;
    }
    [self.playButton setTitle:@"Play video" forState:UIControlStateNormal];
    self.playButton.enabled = true;
}

#pragma mark IBActions

- (IBAction)playButtonDidTouchUpInside {
    
    // Check parameters
    NSString * manifestUrl = self.manifestUrlTextField.text;
    NSUInteger channelId = [self.channelIdTextField.text integerValue];
    NSString * backendUrl = self.backendUrlTextField.text;
    NSString * stunServerUrl = self.stunServerUrlTextField.text;
    if (manifestUrl == nil
        || self.channelIdTextField.text == nil
        || backendUrl == nil
        || stunServerUrl == nil) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Invalid parameters" message:@"Any or some parameters are invalid" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:true completion:nil];
        return;
    }
    
    // UI
    self.playButton.enabled = false;
    [self.playButton setTitle:@"Connecting to PolyNet" forState:UIControlStateNormal];
    
    // Create the PolyNet
    self.polyNet = [[S73PolyNet alloc] initWithManifestUrl:manifestUrl channelId:channelId backendUrl:backendUrl stunServerUrl:stunServerUrl];
    self.polyNet.delegate = self;
    self.polyNet.dataSource = self;
    [self.polyNet connect];
}

#pragma mark S73PolyNetDelegate

// PolyNet did connect. Start the player with the polyNetManifestUrl
- (void)polyNet:(S73PolyNet *)polyNet didConnectWithPolyNetManifestUrl:(NSString *)polyNetManifestUrl {
    
    // Configure and start player
    self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:polyNetManifestUrl]];
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.player = self.player;
    [self presentViewController:self.playerViewController animated:true completion:^{
        [self.player play];
    }];
}

// PolyNet did fail
- (void)polyNet:(S73PolyNet *)polyNet didFailWithError:(NSError *)error {
    
#pragma mark TODO: Manage the error if needed.
    NSLog(@"PolyNet error: %@", error.localizedDescription);
}

#pragma mark S73PolyNetDataSource

// PolyNet request the buffer health of the player. This is the playback duration the player can play for sure before a possible stall.
- (NSNumber *)playerBufferHeathInPolyNet:(S73PolyNet *)polyNet {
    
    // If no events, returns nil
    AVPlayerItemAccessLogEvent * event = [self.player.currentItem accessLog].events.lastObject;
    if (event == nil) {
        return nil;
    }
    
    // Get the last event and return buffer health. If any value is negative, the value is unknown according to the API. In such cases return nil.
    NSTimeInterval durationDownloaded = event.segmentsDownloadedDuration;
    NSTimeInterval durationWatched = event.durationWatched;
    if (durationDownloaded < 0 || durationWatched < 0) {
        return nil;
    }
    return [NSNumber numberWithDouble:(durationDownloaded - durationWatched)];
}

// PolyNet request the dropped video frames. This is the accumulated number of dropped video frames for the player.
- (NSNumber *)playerAccumulatedDroppedFramesInPolyNet:(S73PolyNet *)polyNet {
    
    // If no events, returns nil
    AVPlayerItemAccessLogEvent * event = [self.player.currentItem accessLog].events.lastObject;
    if (event == nil) {
        return nil;
    }
    
    // Get the last event and return the dropped frames. If the value is negative, the value is unknown according to the API. In such cases return nil.
    NSInteger numberOfDroppedVideoFrames = event.numberOfDroppedVideoFrames;
    if (numberOfDroppedVideoFrames < 0) {
        return nil;
    } else {
        return [NSNumber numberWithInteger:numberOfDroppedVideoFrames];
    }
}

// PolyNet request the started date of the playback. This is the date when the player started to play the video
- (NSDate *)playerPlaybackStartDateInPolyNet:(S73PolyNet *)polyNet {
    
    // If no events, returns nil
    AVPlayerItemAccessLogEvent * event = [self.player.currentItem accessLog].events.lastObject;
    if (event == nil) {
        return nil;
    }
    return event.playbackStartDate;
}

@end
