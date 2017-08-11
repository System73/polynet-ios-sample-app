//
//  ViewController.m
//  PolyNetSampleObjectiveC
//
//  Created by System73.
//  Copyright © 2017 System73.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <PolyNetSDK/PolyNetSDK.h>

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
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@end

@implementation ViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"PolyNet SDK sample app";
    [self loadFromPersistance];
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Remove a previous polyNet instance
    if (self.polyNet) {
        [self.polyNet close];
        self.polyNet = nil;
    }
    [self.playButton setTitle:@"Play!" forState:UIControlStateNormal];
    self.playButton.enabled = true;
    
    [self updateVersionLabel];
}

#pragma mark User defaults

#define MANIFEST_URL_KEY @"MANIFEST_URL_KEY"
#define CHANNEL_ID_KEY @"CHANNEL_ID_KEY"
#define BACKEND_URL_KEY @"BACKEND_URL_KEY"
#define STUN_SERVER_URL_KEY @"STUN_SERVER_URL_KEY"
#define FIRST_SECTION_HEADER_HEIGHT 40.0
#define SECTION_HEADER_HEIGHT 12.0

- (void)loadFromPersistance {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * manifestUrl = [defaults objectForKey:MANIFEST_URL_KEY];
    if (manifestUrl) {
        self.manifestUrlTextField.text = manifestUrl;
    }
    NSNumber * channelId = [defaults objectForKey:CHANNEL_ID_KEY];
    if (channelId) {
        self.channelIdTextField.text = [NSString stringWithFormat:@"%ld", (long)[channelId integerValue]];
    }
    NSString * backendUrl = [defaults objectForKey:BACKEND_URL_KEY];
    if (backendUrl) {
        self.backendUrlTextField.text = backendUrl;
    }
    NSString * stunServerUrl = [defaults objectForKey:STUN_SERVER_URL_KEY];
    if (stunServerUrl) {
        self.stunServerUrlTextField.text = stunServerUrl;
    }
}

- (void)saveToPersistance {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * manifestUrl = self.manifestUrlTextField.text;
    if (manifestUrl != nil && [manifestUrl length] > 0) {
        [defaults setObject:manifestUrl forKey:MANIFEST_URL_KEY];
    }
    NSNumberFormatter * formater = [[NSNumberFormatter alloc] init];
    formater.numberStyle = NSNumberFormatterNoStyle;
    NSNumber * channelId = [formater numberFromString:self.channelIdTextField.text];
    if (channelId != nil) {
        [defaults setObject:channelId forKey:CHANNEL_ID_KEY];
    }
    NSString * backendUrl = self.backendUrlTextField.text;
    if (backendUrl != nil && [backendUrl length] > 0) {
        [defaults setObject:backendUrl forKey:BACKEND_URL_KEY];
    }
    NSString * stunServerUrl = self.stunServerUrlTextField.text;
    if (stunServerUrl != nil && [stunServerUrl length] > 0) {
        [defaults setObject:stunServerUrl forKey:STUN_SERVER_URL_KEY];
    }
}

- (void)updateVersionLabel {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    self.versionLabel.text = [NSString stringWithFormat:@"Sample App v%@.%@\nPolyNet SDK v.%@",
                              [dict objectForKey:@"CFBundleShortVersionString"],
                              [dict objectForKey:@"CFBundleVersion"],
                              [S73PolyNet version]];
}

#pragma mark IBActions

- (IBAction)playButtonDidTouchUpInside {
    
    // Parameters
    NSString * manifestUrl;
    if (self.manifestUrlTextField.text == nil || [self.manifestUrlTextField.text length] == 0) {
        manifestUrl = self.manifestUrlTextField.placeholder;
    } else {
        manifestUrl = self.manifestUrlTextField.text;
    }
    NSUInteger channelId;
    if (self.channelIdTextField.text == nil || [self.channelIdTextField.text length] == 0) {
        channelId = [self.channelIdTextField.placeholder integerValue];
    } else {
        channelId = [self.channelIdTextField.text integerValue];
    }
    NSString * backendUrl;
    if (self.backendUrlTextField.text == nil || [self.backendUrlTextField.text length] == 0) {
        backendUrl = self.backendUrlTextField.placeholder;
    } else {
        backendUrl = self.backendUrlTextField.text;
    }
    NSString * stunServerUrl;
    if (self.stunServerUrlTextField.text == nil || [self.stunServerUrlTextField.text length] == 0) {
        stunServerUrl = self.stunServerUrlTextField.placeholder;
    } else {
        stunServerUrl = self.stunServerUrlTextField.text;
    }
    
    // Save to persistance
    [self loadFromPersistance];
    
    // UI
    self.playButton.enabled = false;
    [self.playButton setTitle:@"Connecting to PolyNet" forState:UIControlStateNormal];
    
    // Create the PolyNet
    self.polyNet = [[S73PolyNet alloc] initWithManifestUrl:manifestUrl channelId:channelId backendUrl:backendUrl stunServerUrl:stunServerUrl];
    [self.polyNet setDebugMode:YES];
    self.polyNet.delegate = self;
    self.polyNet.dataSource = self;
    [self.polyNet connect];
}

- (IBAction)goToWeb {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://system73.com"] options:@{} completionHandler:nil];
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

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return [self tableView:tableView heightForHeaderInSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return FIRST_SECTION_HEADER_HEIGHT;
    }
    
    return SECTION_HEADER_HEIGHT;
}


@end
