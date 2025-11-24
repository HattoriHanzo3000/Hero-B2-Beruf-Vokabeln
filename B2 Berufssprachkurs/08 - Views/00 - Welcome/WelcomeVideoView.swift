//
//  WelcomeVideoView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import AVFoundation

struct WelcomeVideoView: View {
    @Binding var hasSeenWelcomeVideo: Bool
    @State private var player: AVPlayer?
    @State private var endObserver: NSObjectProtocol?
    @State private var didComplete: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // Background color matching app theme
            Color.accentColor
                .ignoresSafeArea()
            
            if let player = player {
                AlphaVideoPlayerView(player: player, videoGravity: .resizeAspect)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else {
                // Loading state
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color("AppGreen"))
            }
        }
        .onAppear {
            setupAudioSession()
            setupVideo()
        }
        .onDisappear {
            cleanupPlayback()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Pause video when app goes to background
            switch newPhase {
            case .active:
                break
            case .inactive, .background:
                player?.pause()
            @unknown default:
                player?.pause()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // AVAudioSession configuration failed - continue silently
        }
    }
    
    private func setupVideo() {
        // Find video file with multiple extension support
        let possibleExtensions = ["mov", "mp4"]
        var videoURL: URL?
        for ext in possibleExtensions {
            if let url = Bundle.main.url(forResource: "welcome_animation", withExtension: ext) {
                videoURL = url
                break
            }
        }
        
        guard let resolvedURL = videoURL else {
            // Video file not found - mark as seen and continue
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completeWelcome()
            }
            return
        }
        
        let playerItem = AVPlayerItem(url: resolvedURL)
        
        // Async video loading
        Task { @MainActor in
            do {
                _ = try await playerItem.asset.load(.tracks)
            } catch {
                // Video track loading failed - continue with playback
            }
            
            let player = AVPlayer(playerItem: playerItem)
            player.actionAtItemEnd = .pause
            
            // Unmute for welcome video
            player.isMuted = false
            
            self.player = player
            setupVideoCompletion(for: player)
            player.play()
        }
    }
    
    private func setupVideoCompletion(for player: AVPlayer) {
        // Remove previous observer if any
        if let token = endObserver {
            NotificationCenter.default.removeObserver(token)
            endObserver = nil
        }
        
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completeWelcome()
            }
        }
    }
    
    private func cleanupPlayback() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        if let token = endObserver {
            NotificationCenter.default.removeObserver(token)
            endObserver = nil
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            // Non-fatal; OK to ignore
        }
    }
    
    private func completeWelcome() {
        guard !didComplete else { return }
        didComplete = true
        hasSeenWelcomeVideo = true
    }
}

// MARK: - Video Player Components
final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
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
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = videoGravity
    }
}

#Preview {
    WelcomeVideoView(hasSeenWelcomeVideo: .constant(false))
}

