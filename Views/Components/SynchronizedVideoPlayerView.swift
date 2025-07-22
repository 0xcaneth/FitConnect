import SwiftUI
import AVFoundation

// Synchronized video player that notifies when video is ready and responds to play/pause commands
struct SynchronizedVideoPlayerView: View {
    let url: URL
    let isPlaying: Bool
    let onVideoReady: () -> Void
    
    var body: some View {
        SynchronizedVideoPlayerRepresentable(
            url: url,
            isPlaying: isPlaying,
            shouldLoop: true,
            onVideoReady: onVideoReady
        )
    }
}

struct SynchronizedVideoPlayerRepresentable: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool
    let shouldLoop: Bool
    let onVideoReady: () -> Void
    
    func makeUIView(context: Context) -> SynchronizedVideoPlayerUIView {
        let view = SynchronizedVideoPlayerUIView()
        view.configure(url: url, shouldLoop: shouldLoop, onVideoReady: onVideoReady)
        return view
    }
    
    func updateUIView(_ uiView: SynchronizedVideoPlayerUIView, context: Context) {
        if isPlaying {
            uiView.play()
        } else {
            uiView.pause()
        }
    }
}

class SynchronizedVideoPlayerUIView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var onVideoReady: (() -> Void)?
    private var hasNotifiedReady = false
    
    func configure(url: URL, shouldLoop: Bool, onVideoReady: @escaping () -> Void) {
        backgroundColor = .black
        self.onVideoReady = onVideoReady
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = bounds
        playerLayer?.backgroundColor = UIColor.black.cgColor
        
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
        
        if shouldLoop {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                // Don't auto-play when looping - wait for manual command
            }
        }
        
        // FASTER ready notification - multiple triggers
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        // BACKUP: If video loads fast enough, notify immediately
        if playerItem.status == .readyToPlay {
            DispatchQueue.main.async {
                self.onVideoReady?()
            }
        }
        
        // BACKUP 2: Force ready after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.hasNotifiedReady {
                print("[SyncVideo] 🚀 Force-ready after 0.5s")
                self.hasNotifiedReady = true
                self.onVideoReady?()
            }
        }
        
        // Pre-load the video but don't play it
        player?.pause()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                if playerItem.status == .readyToPlay && !hasNotifiedReady {
                    hasNotifiedReady = true
                    DispatchQueue.main.async {
                        print("[SyncVideo] ✅ Video ready via status observer")
                        self.onVideoReady?()
                    }
                } else if playerItem.status == .failed && !hasNotifiedReady {
                    // Even if video fails, allow workout to continue
                    hasNotifiedReady = true
                    DispatchQueue.main.async {
                        print("[SyncVideo] ❌ Video failed but allowing workout to continue")
                        self.onVideoReady?()
                    }
                }
            }
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
        player?.pause()
        NotificationCenter.default.removeObserver(self)
    }
}