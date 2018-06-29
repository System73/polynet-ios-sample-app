
import UIKit
import AVKit
import AVFoundation
import PolyNetSDK

class ViewController: UITableViewController {
    
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
        
        updateVersionLabel()
        deactivateBufferEmptyCountermeasure()
        if (player != nil) {
            removeObserversForPlayerItem(playerItem: (player?.currentItem)!)
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
        channelIdTextField.text = defaults.string(forKey: CHANNEL_ID_KEY)
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
        
        versionLabel.text = String(format: "Sample App v.%@-%@\nPolyNet SDK v.%@",
                                   dict["CFBundleShortVersionString"] as! String,
                                   dict["CFBundleVersion"] as! String,
                                   PolyNet.frameworkVersion)
    }
    
    // MARK: IBActions and IBOutlets
    
    @IBOutlet weak var manifestUrlTextField: UITextField!
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func playButtonDidTouchUpInside() {
        // Save to persistance
        removeWhiteSpaces()
        if checkParameters() {
            playVideo()
            saveToPersistance()
        }
    }
    
    func removeWhiteSpaces() {
        manifestUrlTextField.text = manifestUrlTextField.text?.replacingOccurrences(of: " ", with: "")
        channelIdTextField.text = channelIdTextField.text?.replacingOccurrences(of: " ", with: "")
        apiKeyTextField.text = apiKeyTextField.text?.replacingOccurrences(of: " ", with: "")
    }
    
    func checkParameters() -> Bool {
        guard let existManifestUrl = manifestUrlTextField.text,
            let existChannelIdString = channelIdTextField.text,
            let exitApiKey = apiKeyTextField.text else {
            showAlertView(message: "Please, fill in all fields")
            return false
        }
        
        guard existManifestUrl.count > 0
            && existChannelIdString.count > 0
            && exitApiKey.count > 0 else {
                showAlertView(message: "Please, fill in all fields")
                return false
        }
        
        return true
    }
    
    func playVideo() {
        // UI
        playButton.isEnabled = false
        playButton.setTitle("Connecting to PolyNet", for: .normal)
        // Create the PolyNet
        do {
            polyNet = try PolyNet(manifestUrl: manifestUrlTextField.text!, channelId: channelIdTextField.text!, apiKey: apiKeyTextField.text!)
            polyNet?.dataSource = self
            polyNet?.delegate = self
            
            // Configure and start player
            player = AVPlayer(url: URL(string:polyNet!.localManifestUrl)!)
            playerViewController = AVPlayerViewController()
            playerViewController?.player = player
            self.addObserversForPlayerItem(playerItem: (self.player?.currentItem)!)
            present(playerViewController!, animated: true) {
            }
        } catch  {
            print("PolyNet Error: creating PolyNet object")
        }
    }
    
    func showAlertView(message:String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func goToWeb() {
        UIApplication.shared.open(URL(string:"https://www.system73.com")!, options: [:], completionHandler:nil)
    }
}

// MARK: PolyNetDelegate
extension ViewController: PolyNetDelegate {
    
    
    /// PolyNet Updated Metrics Delegate Method
    ///
    /// - Parameters:
    ///   - polyNet: The PolyNet instance to which the metrics object belong.
    ///   - metrics: An updated PolyNetMetrics Object.
    func polyNet(_ polyNet: PolyNet, didUpdate metrics: PolyNetMetrics) {
        // TODO: You can now access the new metrics object.
    }

    /// PolyNet did fail Delegate Method
    ///
    /// - Parameters:
    ///   - polyNet: The PolyNet instance where the error generated.
    ///   - error: A PolyNet Error. See the debugging section in the docs for more info at: https://system73.com/docs/
    func polyNet(_ polyNet: PolyNet, didFailWithError error: Error) {
        // TODO: Manage the error if needed.
        print("PolyNet error: " + error.localizedDescription)
    }
}

// MARK: PolyNetDataSource
extension ViewController: PolyNetDataSource {

    // PolyNet requests the buffer health of the video player.
    // This is the current buffered time ready to be played.
    func playerBufferHealth(in: PolyNet) -> NSNumber? {
        // Get player time ranges. If not, return nil
        guard let timeRanges: [NSValue] = player?.currentItem?.loadedTimeRanges,
            timeRanges.count > 0,
            let currentTime = player?.currentItem?.currentTime()
            else {
                return nil
        }
        // Get the valid time range from time ranges, return nil if not valid one.
        guard let timeRange = getTimeRange(timeRanges: timeRanges, forCurrentTime: currentTime) else {
            return nil
        }
        let end = timeRange.end.seconds
        return max(end - currentTime.seconds, 0) as NSNumber
    }
    
    func getTimeRange(timeRanges: [NSValue], forCurrentTime time: CMTime) -> CMTimeRange? {
        let timeRange = timeRanges.first(where: { (value) -> Bool in
            CMTimeRangeContainsTime(value.timeRangeValue, time)
        })
        // Workaround: When pause the player, the item loaded ranges moves whereas the current time
        // remains equal. In time, the current time is out of the range, so the buffer health cannot
        // be calculated. For this reason, when there is not range for current item, the first range
        // is returned to calculate the buffer with it.
        if timeRange == nil && timeRanges.count > 0 {
            return timeRanges.first!.timeRangeValue
        }
        return timeRange?.timeRangeValue
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
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return self.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0) {
            return FIRST_SECTION_HEADER_HEIGHT
        }
        
        return SECTION_HEADER_HEIGHT
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
        
        bufferEmptyCountermeasureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
            guard self != nil else { return }
            let currentItem: AVPlayerItem = (self?.player?.currentItem)!
            self?.removeObserversForPlayerItem(playerItem: currentItem)
            
            let asset = currentItem.asset
            
            guard let urlAsset = asset as? AVURLAsset else {
                return
            }
            
            let item: AVPlayerItem = AVPlayerItem.init(url: urlAsset.url)
            self?.addObserversForPlayerItem(playerItem: item)
            self?.player?.replaceCurrentItem(with: item)
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

