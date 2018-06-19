//
//  ViewController.swift
//  PolyNetSample-tvOS
//
//  Created by harris on 11/20/17.
//  Copyright © 2017 System73. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import PolyNetSDK

class ViewController: UIViewController {
    
    // MARK: Properties
    
    var polyNet: PolyNet?
    var playerViewController: AVPlayerViewController?
    var player: AVPlayer?
    var bufferEmptyCountermeasureTimer : Timer? = nil
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "PolyNet SDK sample app"
        loadFromPersistance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Remove a previous polyNet instance
        if polyNet != nil {
            polyNet?.close()
            polyNet = nil
        }
        playButton.setTitle("Play!", for: .normal)
        playButton.isEnabled = true
        
        self.updateVersionLabel()
        deactivateBufferEmptyCountermeasure()
        if (player != nil) {
            removeObserversForPlayerItem(playerItem: (player?.currentItem)!);
        }
    }
    
    // MARK: User defaults
    
    fileprivate let MANIFEST_URL_KEY = "MANIFEST_URL_KEY"
    fileprivate let CHANNEL_ID_KEY = "CHANNEL_ID_KEY"
    fileprivate let API_KEY_KEY = "API_KEY_KEY"
    fileprivate let FIRST_SECTION_HEADER_HEIGHT = CGFloat(40.0)
    fileprivate let SECTION_HEADER_HEIGHT = CGFloat(12.0)
    
    fileprivate func loadFromPersistance() {
        let defaults = UserDefaults.standard
        manifestUrlTextField.text = defaults.string(forKey: MANIFEST_URL_KEY)
        if defaults.integer(forKey: CHANNEL_ID_KEY) != 0 {
            channelIdTextField.text = "\(defaults.integer(forKey: CHANNEL_ID_KEY))"
        }
        apiKeyTextField.text = defaults.string(forKey: API_KEY_KEY)
    }
    
    fileprivate func saveToPersistance() {
        let defaults = UserDefaults.standard
        if let manifestUrl = manifestUrlTextField.text, manifestUrl.count > 0 {
            defaults.set(manifestUrl, forKey: MANIFEST_URL_KEY)
        } else {
            defaults.removeObject(forKey: MANIFEST_URL_KEY)
        }
        if let channelIdString = channelIdTextField.text, channelIdString.count > 0 {
            defaults.set(channelIdString, forKey: CHANNEL_ID_KEY)
        } else {
            defaults.removeObject(forKey: CHANNEL_ID_KEY)
        }
        if let apiKey = apiKeyTextField.text, apiKey.count > 0 {
            defaults.set(apiKey, forKey: API_KEY_KEY)
        } else {
            defaults.removeObject(forKey: API_KEY_KEY)
        }
    }
    
    fileprivate func updateVersionLabel() {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            return
        }
        
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            return
        }
        
        versionLabel.text = String(format: "Sample App v%@-%@\nPolyNet SDK v.%@",
                                   dict["CFBundleVersion"] as! String,
                                   dict["CFBundleShortVersionString"] as! String,
                                   PolyNet.version())
    }
    
    // MARK: IBActions and IBOutlets
    
    @IBOutlet weak var manifestUrlTextField: UITextField!
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func playButtonActionTriggered(_ sender: Any) {
        // Parameters
        let manifestUrl: String
        if manifestUrlTextField.text == nil || manifestUrlTextField.text?.count == 0 {
            manifestUrl = manifestUrlTextField.placeholder!
        } else {
            manifestUrl = manifestUrlTextField.text!
        }
        
        let channelId: String
        if channelIdTextField.text == nil || channelIdTextField.text?.count == 0 {
            channelId = channelIdTextField.placeholder!
        } else {
            channelId = channelIdTextField.text!
        }
        
        let apiKey: String
        if apiKeyTextField.text == nil || apiKeyTextField.text?.count == 0 {
            apiKey = apiKeyTextField.placeholder!
        } else {
            apiKey = apiKeyTextField.text!
        }
        
        
        // Remove White Spaces
        removeWhiteSpaces()
        
        // Save to persistance
        saveToPersistance()
        
        // UI
        playButton.isEnabled = false
        playButton.setTitle("Connecting to PolyNet", for: .normal)
        
        // Create the PolyNet
        polyNet = PolyNet(manifestUrl: manifestUrl, channelId: channelId, apiKey: apiKey)
        polyNet?.setDebugMode(true)
        polyNet?.dataSource = self
        
        // Configure and start player
        player = AVPlayer(url: URL(string:polyNet!.localManifestUrl)!)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        self.addObserversForPlayerItem(playerItem: (self.player?.currentItem)!)
        present(playerViewController!, animated: true) {
            
        }    }
    
    func removeWhiteSpaces() {
        manifestUrlTextField.text = manifestUrlTextField.text?.replacingOccurrences(of: " ", with: "")
        channelIdTextField.text = channelIdTextField.text?.replacingOccurrences(of: " ", with: "")
        apiKeyTextField.text = apiKeyTextField.text?.replacingOccurrences(of: " ", with: "")

    }

}

extension ViewController: PolyNetDataSource {
    
    // MARK: S73PolyNetDataSource
    
    // PolyNet request the buffer health of the player. This is the playback duration the player can play for sure before a possible stall.
    func playerBufferHeath(in: PolyNet) -> NSNumber? {
        
        // If no events, returns nil
        guard let event = player?.currentItem?.accessLog()?.events.last else {
            return nil
        }
        
        // Get the last event and return buffer health. If any value is negative, the value is unknown according to the API. In such cases return nil.
        let durationDownloaded = event.segmentsDownloadedDuration
        let durationWatched = event.durationWatched
        guard durationDownloaded >= 0 && durationWatched >= 0 else {
            return nil
        }
        return durationDownloaded - durationWatched as NSNumber
    }
    
    // PolyNet request the dropped video frames. This is the accumulated number of dropped video frames for the player.
    func playerAccumulatedDroppedFrames(in: PolyNet) -> NSNumber? {
        
        // If no events, return nil
        guard let event = player?.currentItem?.accessLog()?.events.last else {
            return nil
        }
        
        // Get the last event and return the dropped frames. If the value is negative, the value is unknown according to the API. In such cases return nil.
        let numberOfDroppedVideoFrames = event.numberOfDroppedVideoFrames
        if (numberOfDroppedVideoFrames < 0) {
            return nil
        } else {
            return numberOfDroppedVideoFrames as NSNumber
        }
    }
    
    // PolyNet request the started date of the playback. This is the date when the player started to play the video
    func playerPlaybackStartDate(in: PolyNet) -> Date? {
        
        // If no events, return nil
        guard let event = player?.currentItem?.accessLog()?.events.last else {
            return nil
        }
        return event.playbackStartDate
    }
}

// Extension to handle connection lost and playback recovery
extension ViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (#keyPath(AVPlayerItem.status) == keyPath) {
            let playerItem = object as! AVPlayerItem
            switch playerItem.status {
            case .readyToPlay:
                self.handlePlayerItemReadyToPlay()
                break
            case .unknown: fallthrough
            case .failed:
                break
            }
            
        }
        
        if (keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty)) {
            handlePlaybackBuferEmpty(playerItem: object as! AVPlayerItem)
        }
    }
    
    func addObserversForPlayerItem(playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.initial , .new], context: nil)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.initial , .new], context: nil)
    }
    
    func removeObserversForPlayerItem(playerItem: AVPlayerItem) {
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
    }
    
    func handlePlayerItemReadyToPlay() {
        player?.play()
        deactivateBufferEmptyCountermeasure()
    }
    
    func handlePlaybackBuferEmpty(playerItem: AVPlayerItem) {
        if (playerItem.status == .readyToPlay) {
            activateBufferEmptyCountermeasure()
        }
    }
    
    func activateBufferEmptyCountermeasure() {
        guard bufferEmptyCountermeasureTimer == nil else {
            return
        }
        
        bufferEmptyCountermeasureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
            let currentItem: AVPlayerItem = (self.player?.currentItem)!
            self.removeObserversForPlayerItem(playerItem: currentItem)
            
            let asset = currentItem.asset
            
            guard let urlAsset = asset as? AVURLAsset else {
                return
            }
            
            let item: AVPlayerItem = AVPlayerItem.init(url: urlAsset.url)
            self.addObserversForPlayerItem(playerItem: item)
            self.player?.replaceCurrentItem(with: item)
        }
    }
    
    func deactivateBufferEmptyCountermeasure() {
        guard bufferEmptyCountermeasureTimer != nil else {
            return
        }
        
        bufferEmptyCountermeasureTimer?.invalidate()
        bufferEmptyCountermeasureTimer = nil
    }
    
}

