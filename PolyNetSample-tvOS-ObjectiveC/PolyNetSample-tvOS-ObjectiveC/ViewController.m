//
//  ViewController.m
//  PolyNetSample-tvOS-ObjectiveC
//
//  Created by Daniel Méndez on 19/12/2019.
//  Copyright © 2019 System73. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <PolyNetSDK/PolyNetSDK.h>

@interface ViewController () <PolyNetDelegate, PolyNetDataSource>

#pragma mark Properties

@property (nonatomic, nullable, strong) PolyNet * polyNet;
@property (nonatomic, nullable, strong) AVPlayerViewController * playerViewController;
@property (nonatomic, nullable, strong) AVPlayer * player;
@property (nonatomic, nullable, strong) NSTimer *bufferEmptyCountermeasureTimer;

#pragma mark IBOutlets

@property (weak, nonatomic) IBOutlet UITextField *manifestUrlTextField;
@property (weak, nonatomic) IBOutlet UITextField *channelIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *apiKeyTextField;
@property (weak, nonatomic) IBOutlet UITextField *contentSteeringEndpointTextField;
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
#define API_KEY_KEY @"API_KEY_KEY"
#define CONTENT_STEERING_ENDPOINT_KEY @"CONTENT_STEERING_ENDPOINT_KEY"
#define FIRST_SECTION_HEADER_HEIGHT 40.0
#define SECTION_HEADER_HEIGHT 12.0

- (void)loadFromPersistance {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    self.manifestUrlTextField.text = [defaults objectForKey:MANIFEST_URL_KEY];
    self.channelIdTextField.text =  [defaults objectForKey:CHANNEL_ID_KEY];
    self.apiKeyTextField.text = [defaults objectForKey:API_KEY_KEY];
    self.contentSteeringEndpointTextField.text = [defaults objectForKey:CONTENT_STEERING_ENDPOINT_KEY];
}

- (void)saveToPersistance {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * manifestUrl = self.manifestUrlTextField.text;
    if (manifestUrl != nil && [manifestUrl length] > 0) {
        [defaults setObject:manifestUrl forKey:MANIFEST_URL_KEY];
    } else {
        [defaults removeObjectForKey:MANIFEST_URL_KEY];
    }
    NSString * channelId = self.channelIdTextField.text;
    if (channelId != nil && [channelId length] > 0) {
        [defaults setObject:channelId forKey:CHANNEL_ID_KEY];
    } else {
        [defaults removeObjectForKey:CHANNEL_ID_KEY];
    }
    NSString * apiKey = self.apiKeyTextField.text;
    if (apiKey != nil && [apiKey length] > 0) {
        [defaults setObject:apiKey forKey:API_KEY_KEY];
    } else {
        [defaults removeObjectForKey:API_KEY_KEY];
    }
    NSString * contentSteeringEndpoint = self.contentSteeringEndpointTextField.text;
    if (contentSteeringEndpoint != nil && [contentSteeringEndpoint length] > 0) {
        [defaults setObject:contentSteeringEndpoint forKey:CONTENT_STEERING_ENDPOINT_KEY];
    } else {
        [defaults removeObjectForKey:CONTENT_STEERING_ENDPOINT_KEY];
    }
}

- (void)updateVersionLabel {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    self.versionLabel.text = [NSString stringWithFormat:@"Sample App v%@-%@\nPolyNet SDK %@",
                              [dict objectForKey:@"CFBundleShortVersionString"],
                              [dict objectForKey:@"CFBundleVersion"],
                              [PolyNet frameworkVersion]];
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
    NSString * channelId;
    if (self.channelIdTextField.text == nil || [self.channelIdTextField.text length] == 0) {
        channelId = self.channelIdTextField.placeholder;
    } else {
        channelId = self.channelIdTextField.text;
    }
    NSString * apiKey;
    if (self.apiKeyTextField.text == nil || [self.apiKeyTextField.text length] == 0) {
        apiKey = self.apiKeyTextField.placeholder;
    } else {
        apiKey = self.apiKeyTextField.text;
    }
    NSString * contentSteeringEndpoint;
    if (self.contentSteeringEndpointTextField.text == nil || [self.contentSteeringEndpointTextField.text length] == 0) {
        contentSteeringEndpoint = self.contentSteeringEndpointTextField.placeholder;
    } else {
        contentSteeringEndpoint = self.contentSteeringEndpointTextField.text;
    }
    
    // Save to persistance
    [self saveToPersistance];
    
    // UI
    self.playButton.enabled = false;
    [self.playButton setTitle:@"Connecting to PolyNet" forState:UIControlStateNormal];
    
    // Create the PolyNet
    NSError * error = nil;
    self.polyNet = [[PolyNet alloc] initWithManifestUrl:manifestUrl channelId:channelId apiKey:apiKey contentSteeringEndpoint:contentSteeringEndpoint error:&error];
    if (self.polyNet != nil) {
        self.polyNet.logLevel = PolyNetLogLevelDebug;
        self.polyNet.delegate = self;
        self.polyNet.dataSource = self;
        self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:self.polyNet.localManifestUrl]];
        self.playerViewController = [[AVPlayerViewController alloc] init];
        self.playerViewController.player = self.player;
        [self addObserversForPlayerItem:self.player.currentItem];
        [self presentViewController:self.playerViewController animated:true completion:nil];
    } else {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NULL message: error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        self.playButton.enabled = true;
                                        [self.playButton setTitle:@"Play!" forState:UIControlStateNormal];
                                    }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        NSLog(@"%@", error.localizedDescription);
    }
}

- (IBAction)goToWeb {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://system73.com"] options:@{} completionHandler:nil];
}

#pragma mark PolyNetDelegate
/**
 PolyNet Updated Metrics Delegate Method

 @param polyNet The PolyNet instance to which the metrics object belong.
 @param metrics An updated PolyNetMetrics Object.
 */
- (void)polyNet:(PolyNet *)polyNet didUpdateMetrics:(PolyNetMetrics *)metrics {
    #pragma mark TODO: You can now access the new metrics object.
}


/**
 PolyNet did fail Delegate Method

 @param polyNet The PolyNet instance where the error generated.
 @param error A PolyNet Error. See the debugging section in the docs for more info at: https://system73.com/docs/
 */
- (void)polyNet:(PolyNet *)polyNet didFailWithError:(NSError *)error {
    #pragma mark TODO: Manage the error if needed.
    NSLog(@"PolyNet error: %@", error.localizedDescription);
}


#pragma mark PolyNetDataSource

// PolyNet request the buffer health of the player. This is the playback duration the player can play for sure before a possible stall.
- (NSNumber *)playerBufferHealthIn:(PolyNet *)polyNet {
    // Get player time ranges. If not, return nil
    NSArray<NSValue *> * timeRanges = self.player.currentItem.loadedTimeRanges;
    if (timeRanges == nil || [timeRanges count] == 0 || self.player.currentItem == nil) {
        return nil;
    }
    // Get the valid time range from time ranges, return nil if not valid one.
    NSValue * timeRange = [self getTimeRangeFrom:timeRanges forCurrentTime:self.player.currentItem.currentTime];
    if (timeRange == nil) {
        return nil;
    }
    double seconds = CMTimeGetSeconds(CMTimeSubtract(CMTimeRangeGetEnd(timeRange.CMTimeRangeValue), self.player.currentItem.currentTime));
    double max = MAX(seconds, 0);
    return [NSNumber numberWithDouble:max];
}

- (NSValue *)getTimeRangeFrom:(NSArray <NSValue *> *)timeRanges forCurrentTime:(CMTime)time {
    NSValue * timeRange = nil;
    for (NSValue * value in timeRanges) {
        if (CMTimeRangeContainsTime(value.CMTimeRangeValue, time)) {
            timeRange = value;
            break;
        }
    }
    // Workaround: When pause the player, the item loaded ranges moves whereas the current time
    // remains equal. In time, the current time is out of the range, so the buffer health cannot
    // be calculated. For this reason, when there is not range for current item, the first range
    // is returned to calculate the buffer with it.
    if (timeRange == nil && [timeRanges count] > 0) {
        return timeRanges.firstObject;
    }
    return timeRange;
}

// PolyNet request the dropped video frames. This is the accumulated number of dropped video frames for the player.
- (NSNumber *)playerAccumulatedDroppedFramesIn:(PolyNet *)polyNet {
    
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
- (NSDate *)playerPlaybackStartDateIn:(PolyNet *)polyNet {
    
    // If no events, returns nil
    AVPlayerItemAccessLogEvent * event = [self.player.currentItem accessLog].events.lastObject;
    if (event == nil) {
        return nil;
    }
    return event.playbackStartDate;
}

- (enum PolynetPlayerState)playerStateIn:(PolyNet *)polyNet{
    //retrun the exact status of player
    return PolynetPlayerStateStarting;
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

#pragma mark - Handle connection lost and playback recovery
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        switch (playerItem.status) {
            case AVPlayerItemStatusReadyToPlay:
                [self handlePlayerItemReadyToPlay];
                break;
            case AVPlayerItemStatusUnknown:
            case AVPlayerItemStatusFailed:
                break;
        }
        return;
    }
    
    if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        [self handlePlaybackBuferEmpty:(AVPlayerItem*)object];
    }
}

- (void)addObserversForPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserversForPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
}

- (void)handlePlayerItemReadyToPlay {
    [_player play];
    [self deactivateBufferEmptyCountermeasure];
}

- (void)handlePlaybackBuferEmpty:(AVPlayerItem *)playerItem {
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        [self activateBufferEmptyCountermeasure];
    }
}

- (void)activateBufferEmptyCountermeasure {
    if (_bufferEmptyCountermeasureTimer) {
        return;
    }
    
    _bufferEmptyCountermeasureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
        if (self == nil) { return; }
        AVPlayerItem *currentItem = [self.player currentItem];
        [self removeObserversForPlayerItem:currentItem];
        
        AVURLAsset *urlAsset = (AVURLAsset *)currentItem.asset;
        if (!urlAsset) {
            return;
        }
        
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL: urlAsset.URL];
        
        [self addObserversForPlayerItem:item];
        [self.player replaceCurrentItemWithPlayerItem:item];
    }];
}

- (void)deactivateBufferEmptyCountermeasure {
    if (!_bufferEmptyCountermeasureTimer) {
        return;
    }
    
    [_bufferEmptyCountermeasureTimer invalidate];
    _bufferEmptyCountermeasureTimer = nil;
}

@end
