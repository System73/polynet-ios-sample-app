
import UIKit
import AVKit
import AVFoundation
import PolyNetSDK

class ViewController: UITableViewController {
    
    // MARK: Properties
    
    var polyNet: S73PolyNet?
    var playerViewController: AVPlayerViewController?
    var player: AVPlayer?
    var bufferEmptyCountermeasureTimer : Timer? = nil
    var name: String = ""
    var manifestUrl: String = ""
    var channelId: String = ""
    var backendUrl: String = ""
    var stunServerUrl: String = ""
    
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
    fileprivate let BACKEND_URL_KEY = "BACKEND_URL_KEY"
    fileprivate let STUN_SERVER_URL_KEY = "STUN_SERVER_URL_KEY"
    fileprivate let FIRST_SECTION_HEADER_HEIGHT = CGFloat(40.0)
    fileprivate let SECTION_HEADER_HEIGHT = CGFloat(12.0)
    
    
    fileprivate func loadFromPersistance() {
        let defaults = UserDefaults.standard
        if let manifestUrl = defaults.string(forKey: MANIFEST_URL_KEY) {
            self.manifestUrlTextField.text = manifestUrl
        }
        if defaults.integer(forKey: CHANNEL_ID_KEY) != 0 {
            self.channelIdTextField.text = "\(defaults.integer(forKey: CHANNEL_ID_KEY))"
        }
        if let backendUrl = defaults.string(forKey: BACKEND_URL_KEY) {
            self.backendUrlTextField.text = backendUrl
        }
        if let stunServerUrl = defaults.string(forKey: STUN_SERVER_URL_KEY) {
            self.stunServerUrlTextField.text = stunServerUrl
        }
    }
    
    fileprivate func saveToPersistance() {
        let defaults = UserDefaults.standard
        if let manifestUrl = self.manifestUrlTextField.text, manifestUrl.characters.count > 0 {
            defaults.set(manifestUrl, forKey: MANIFEST_URL_KEY)
        }
        if let channelIdString = self.channelIdTextField.text, let channelId = UInt(channelIdString) {
            defaults.set(channelId, forKey: CHANNEL_ID_KEY)
        }
        if let backendUrl = self.backendUrlTextField.text, backendUrl.characters.count > 0 {
            defaults.set(backendUrl, forKey: BACKEND_URL_KEY)
        }
        if let stunServerUrl = self.stunServerUrlTextField.text, stunServerUrl.characters.count > 0 {
            defaults.set(stunServerUrl, forKey: STUN_SERVER_URL_KEY)
        }
    }
    
    fileprivate func updateVersionLabel() {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            return
        }
        
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            return
        }
        
        versionLabel.text = String(format: "Sample App v%@.%@\nPolyNet SDK v.%@",
                                   dict["CFBundleShortVersionString"] as! String,
                                   dict["CFBundleVersion"] as! String,
                                   S73PolyNet.version())
    }
    
    // MARK: IBActions and IBOutlets
    
    @IBOutlet weak var manifestUrlTextField: UITextField!
    @IBOutlet weak var channelIdTextField: UITextField!
    @IBOutlet weak var backendUrlTextField: UITextField!
    @IBOutlet weak var stunServerUrlTextField: UITextField!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBAction func playButtonDidTouchUpInside() {
        // Save to persistance
        saveToPersistance()
        if checkParameters() {
            playVideo()
        }
    }
    
    func checkParameters() -> Bool {
        var canOpenChannel = true
        manifestUrl = manifestUrlTextField.text!
        channelId = channelIdTextField.text!
        backendUrl = backendUrlTextField.text!
        stunServerUrl = stunServerUrlTextField.text!
        
        //Check spaces or invalid urls in parameters
        if manifestUrl == ""||backendUrl == ""||channelId == ""||stunServerUrl == "" {
            showAlertView(message: "There are unfilled fields")
            canOpenChannel = false
        }
        if verifyUrl(urlString: manifestUrl) == false {
            showAlertView(message: "Manifest URL invalid format")
            canOpenChannel = false
        }
        if checkWhiteSpaces(urlString: backendUrl) == false {
            showAlertView(message: "Backend URL has invalid white spaces")
            canOpenChannel = false
        }
        if checkWebSocketUrl(urlString: backendUrl) == false {
            showAlertView(message: "Backend URL invalid format")
            canOpenChannel = false
        }
        if checkWhiteSpaces(urlString: stunServerUrl) == false {
            showAlertView(message: "Stun Server URL has invalid white spaces")
            canOpenChannel = false
        }
        if checkStunUrl(urlString: stunServerUrl) == false {
            showAlertView(message: "Stun Server URL  invalid format")
            canOpenChannel = false
        }
        if canOpenChannel{
            return true
        }
        return false
    }
    
    func playVideo() {
        // UI
        playButton.isEnabled = false
        playButton.setTitle("Connecting to PolyNet", for: .normal)
        // Create the PolyNet
        polyNet = S73PolyNet(manifestUrl: manifestUrl, channelId: UInt(channelId)!, backendUrl: backendUrl, stunServerUrl: stunServerUrl)
        polyNet?.setDebugMode(true)
        polyNet?.delegate = self
        polyNet?.dataSource = self
        polyNet?.connect()
    }
    
    func checkWhiteSpaces(urlString:String) -> Bool {
        let whiteSpace = CharacterSet.whitespaces
        let stringToCompare = urlString.rangeOfCharacter(from: whiteSpace)
        if stringToCompare != nil {
            print("whitespace found")
            return false
        }else{
            return true
        }
    }
    
    func showAlertView(message:String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    func verifyUrl (urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url  = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    func checkWebSocketUrl(urlString:String) -> Bool {
        
        let formattedUrlString = urlString
        if (!formattedUrlString.hasPrefix("ws://") && !formattedUrlString.hasPrefix("WS://")) {
            return false
        }else{
            return true
        }
    }
    
    func checkStunUrl(urlString: String) -> Bool {
        let formattedUrlString = urlString
        if formattedUrlString.hasPrefix("stun:") {
            return true
        }else{
            return false
        }
    }
    
    @IBAction func goToWeb() {
        UIApplication.shared.open(URL(string:"https://www.system73.com")!, options: [:], completionHandler:nil)
    }
}

extension ViewController: S73PolyNetDelegate {
    
    // MARK: S73PolyNetDelegate
    
    // PolyNet did connect. Start the player with the polyNetManifestUrl
    func polyNet(_ polyNet: S73PolyNet, didConnectWithPolyNetManifestUrl polyNetManifestUrl: String) {
        
        // Configure and start player
        player = AVPlayer(url: URL(string: polyNetManifestUrl)!)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        self.addObserversForPlayerItem(playerItem: (self.player?.currentItem)!)
        present(playerViewController!, animated: true) {
            
        }
    }
    
    // PolyNet did fail
    func polyNet(_ polyNet: S73PolyNet, didFailWithError error: Error) {
        
        // TODO: Manage the error if needed.
        print("PolyNet error: " + error.localizedDescription)
    }
}

extension ViewController: S73PolyNetDataSource {
    
    // MARK: S73PolyNetDataSource
    
    // PolyNet request the buffer health of the player. This is the playback duration the player can play for sure before a possible stall.
    func playerBufferHeath(in: S73PolyNet) -> NSNumber? {
        
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
    func playerAccumulatedDroppedFrames(in: S73PolyNet) -> NSNumber? {
        
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
    func playerPlaybackStartDate(in: S73PolyNet) -> Date? {
        
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

