//
//  HeaderView+Mascot.swift
//  B2 Berufssprachkurs
//

import SwiftUI
import UIKit
import AVFoundation

struct MascotView: View {
    static let defaultSize: CGFloat = 100

    @State var showMascotFallbackAnimation = false
    /// Synchronous gate so rapid taps can’t double-enter before playback state commits on the next run loop.
    @State var mascotPlaybackActive = false
    /// Cancels any pending “hide media” work when starting a new play (defensive).
    @State var mascotGifEndWorkItem: DispatchWorkItem?
    @State var autoPlayTask: Task<Void, Never>? = nil
    @State private var mascotPlayer: AVPlayer?
    @State private var playerAssetName: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let autoPlayInterval: TimeInterval = 30.0
    var body: some View {
        ZStack {
            if hasVideoAsset, !reduceMotion, let mascotPlayer {
                AlphaVideoPlayerView(player: mascotPlayer, videoGravity: .resizeAspect)
                    .id(videoMascotAssetName)
                    .frame(width: Self.defaultSize, height: Self.defaultSize)
                    .allowsHitTesting(false)
            } else {
                Image(staticMascotAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.defaultSize, height: Self.defaultSize)
                    .opacity((showMascotFallbackAnimation && !reduceMotion) ? 0 : 1)

                AnimatedGIFView(
                    gifName: gifFallbackAssetName,
                    contentMode: .scaleAspectFit,
                    shouldAnimate: showMascotFallbackAnimation && !reduceMotion
                )
                .id(gifFallbackAssetName)
                .frame(width: Self.defaultSize, height: Self.defaultSize)
                .opacity((showMascotFallbackAnimation && !reduceMotion) ? 1 : 0)
                .allowsHitTesting(false)
            }
        }
        .frame(width: Self.defaultSize, height: Self.defaultSize)
        .scaleEffect(x: -1, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            playAnimationOnly()
        }
        .onAppear {
            preparePlayerIfNeeded()
            startAutoPlay()
        }
        .onChange(of: videoMascotAssetName) { _, _ in
            preparePlayerIfNeeded()
        }
        .onDisappear {
            autoPlayTask?.cancel()
            autoPlayTask = nil
            mascotGifEndWorkItem?.cancel()
            mascotGifEndWorkItem = nil
            mascotPlayer?.pause()
        }
    }

    private var staticMascotAssetName: String {
        if colorScheme == .dark, UIImage(named: "MascotDark") != nil {
            return "MascotDark"
        }
        return "Mascot"
    }

    /// Dark mode uses `MascotAnimationDark.mov`; light mode uses `MascotAnimationLight.mov`.
    private var videoMascotAssetName: String {
        colorScheme == .dark ? "MascotAnimationDark" : "MascotAnimationLight"
    }

    private var hasVideoAsset: Bool {
        VideoBundleLookup.resourceExists(resourceName: videoMascotAssetName)
    }

    /// GIF fallback keeps the existing behavior if video assets are missing in a build.
    private var gifFallbackAssetName: String {
        if colorScheme == .dark, GIFBundleLookup.resourceExists(resourceName: "MascotDark") {
            return "MascotDark"
        }
        return "Mascot"
    }

    /// Matches media duration so static art returns when playback ends.
    private var mascotPlaybackDuration: TimeInterval {
        if let videoDuration = VideoBundleLookup.duration(forResourceName: videoMascotAssetName) {
            return videoDuration
        }
        return GIFBundleLookup.totalAnimationDuration(forResourceName: gifFallbackAssetName) ?? 1.0
    }

    private func preparePlayerIfNeeded() {
        guard hasVideoAsset else {
            mascotPlayer?.pause()
            mascotPlayer = nil
            playerAssetName = nil
            return
        }
        if playerAssetName == videoMascotAssetName, mascotPlayer != nil { return }
        guard let url = VideoBundleLookup.url(forResourceName: videoMascotAssetName) else { return }
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .pause
        player.isMuted = true
        mascotPlayer = player
        playerAssetName = videoMascotAssetName
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func playAnimationOnly() {
        guard !reduceMotion else { return }
        guard !mascotPlaybackActive else { return }

        mascotGifEndWorkItem?.cancel()

        HapticManager.shared.lightImpact()
        mascotPlaybackActive = true
        if hasVideoAsset {
            preparePlayerIfNeeded()
            mascotPlayer?.seek(to: .zero)
            mascotPlayer?.play()
        } else {
            showMascotFallbackAnimation = true
        }

        let work = DispatchWorkItem {
            showMascotFallbackAnimation = false
            mascotPlaybackActive = false
            mascotGifEndWorkItem = nil
            mascotPlayer?.pause()
            mascotPlayer?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        mascotGifEndWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + mascotPlaybackDuration, execute: work)
    }

    func startAutoPlay() {
        autoPlayTask?.cancel()
        autoPlayTask = Task<Void, Never> { [reduceMotion] in
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(autoPlayInterval * 1_000_000_000))
                if Task.isCancelled { break }
                await MainActor.run {
                    playAnimationOnly()
                }
            }
        }
    }
}
