//
//  WelcomeVideoView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import AVFoundation
import os.log

// MARK: - Logger
private let logger = Logger(subsystem: "com.gizatech.B2-Beruf", category: "WelcomeVideoView")

struct WelcomeVideoView: View {
    @Binding var hasSeenWelcomeVideo: Bool
    @State private var player: AVPlayer?
    @State private var endObserver: NSObjectProtocol?
    @State private var didComplete = false
    @State private var timeoutTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if let player = player {
                AlphaVideoPlayerView(player: player, videoGravity: .resizeAspectFill)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color("AppGreen"))
            }
        }
        .onAppear {
            setupVideo()
            startTimeout()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupVideo() {
        // Find video file (try mov first, then mp4)
        guard let url = Bundle.main.url(forResource: "welcome_animation", withExtension: "mov")
            ?? Bundle.main.url(forResource: "welcome_animation", withExtension: "mp4") else {
            logger.warning("Welcome video not found - skipping")
            completeWelcome()
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = false
        
        // Setup completion observer
        // Capture the binding's projected value to update it from the closure
        let binding = $hasSeenWelcomeVideo
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            // Update binding on main thread (we're already on main queue)
            binding.wrappedValue = true
        }
        
        self.player = player
        player.play()
    }
    
    private func startTimeout() {
        timeoutTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if !didComplete {
                    logger.warning("Video timeout - skipping welcome screen")
                    completeWelcome()
                }
            } catch {
                // Task cancelled - video loaded or view disappeared
            }
        }
    }
    
    private func cleanup() {
        timeoutTask?.cancel()
        timeoutTask = nil
        
        if let token = endObserver {
            NotificationCenter.default.removeObserver(token)
            endObserver = nil
        }
        
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
    
    private func completeWelcome() {
        guard !didComplete else { return }
        didComplete = true
        cleanup()
        hasSeenWelcomeVideo = true
    }
}

// MARK: - Video Player Components
final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct AlphaVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity
    
    init(player: AVPlayer, videoGravity: AVLayerVideoGravity = .resizeAspect) {
        self.player = player
        self.videoGravity = videoGravity
    }
    
    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear
        view.isOpaque = false
        let layer = view.playerLayer
        layer.player = player
        layer.isOpaque = false
        layer.backgroundColor = UIColor.clear.cgColor
        layer.videoGravity = videoGravity
        // Frame will be set in layoutSubviews
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = videoGravity
        // Frame will be updated automatically in layoutSubviews
    }
}

#Preview {
    WelcomeVideoView(hasSeenWelcomeVideo: .constant(false))
}
