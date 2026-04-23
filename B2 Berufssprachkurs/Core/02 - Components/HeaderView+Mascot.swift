//
//  HeaderView+Mascot.swift
//  B2 Berufssprachkurs
//

import SwiftUI
import UIKit
import AVFoundation
import Combine

struct MascotView: View {
    static let defaultSize: CGFloat = 100

    @State var showMascotFallbackAnimation = false
    /// Synchronous gate so rapid taps can’t double-enter before playback state commits on the next run loop.
    @State var mascotPlaybackActive = false
    /// Cancels any pending “hide media” work when starting a new play (defensive).
    @State var mascotGifEndWorkItem: DispatchWorkItem?
    @State var autoPlayTask: Task<Void, Never>? = nil
    @State private var playbackDurationTask: Task<Void, Never>? = nil
    @State private var mascotPlayer: AVPlayer?
    @State private var playerAssetName: String?
    /// Hides `AlphaVideoPlayerView` until the item is ready so cold launch never shows an empty layer over the static art.
    @State private var mascotVideoReadyForDisplay = false
    @State private var videoReadyObserver: AnyCancellable?
    @State private var resolvedPlaybackDuration: TimeInterval = 1.0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let autoPlayInterval: TimeInterval = 30.0
    var body: some View {
        ZStack {
            if hasVideoAsset, !reduceMotion, let mascotPlayer {
                Image(staticMascotAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.defaultSize, height: Self.defaultSize)
                    .opacity(mascotVideoReadyForDisplay ? 0 : 1)
                    .allowsHitTesting(false)

                AlphaVideoPlayerView(player: mascotPlayer, videoGravity: .resizeAspect)
                    .id(videoMascotAssetName)
                    .frame(width: Self.defaultSize, height: Self.defaultSize)
                    .opacity(mascotVideoReadyForDisplay ? 1 : 0)
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
            refreshPlaybackDuration()
            startAutoPlay()
        }
        .onChange(of: videoMascotAssetName) { _, _ in
            preparePlayerIfNeeded()
            refreshPlaybackDuration()
        }
        .onDisappear {
            autoPlayTask?.cancel()
            autoPlayTask = nil
            playbackDurationTask?.cancel()
            playbackDurationTask = nil
            mascotGifEndWorkItem?.cancel()
            mascotGifEndWorkItem = nil
            videoReadyObserver?.cancel()
            videoReadyObserver = nil
            mascotPlayer?.pause()
        }
    }

    private var staticMascotAssetName: String {
        "MascotHeader"
    }

    /// Dark mode uses `MascotHeaderAnimationDark.mov`; light mode uses `MascotHeaderAnimationLight.mov`.
    private var videoMascotAssetName: String {
        colorScheme == .dark ? "MascotHeaderAnimationDark" : "MascotHeaderAnimationLight"
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
        resolvedPlaybackDuration
    }

    private func refreshPlaybackDuration() {
        playbackDurationTask?.cancel()
        playbackDurationTask = Task {
            let fallbackDuration = GIFBundleLookup.totalAnimationDuration(forResourceName: gifFallbackAssetName) ?? 1.0
            let duration: TimeInterval
            if hasVideoAsset, let videoDuration = await VideoBundleLookup.duration(forResourceName: videoMascotAssetName) {
                duration = videoDuration
            } else {
                duration = fallbackDuration
            }
            await MainActor.run {
                resolvedPlaybackDuration = duration
            }
        }
    }

    private func preparePlayerIfNeeded() {
        guard hasVideoAsset else {
            videoReadyObserver?.cancel()
            videoReadyObserver = nil
            mascotVideoReadyForDisplay = false
            mascotPlayer?.pause()
            mascotPlayer = nil
            playerAssetName = nil
            return
        }
        if playerAssetName == videoMascotAssetName, mascotPlayer != nil { return }
        guard let url = VideoBundleLookup.url(forResourceName: videoMascotAssetName) else { return }

        videoReadyObserver?.cancel()
        videoReadyObserver = nil
        mascotVideoReadyForDisplay = false

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .pause
        player.isMuted = true
        mascotPlayer = player
        playerAssetName = videoMascotAssetName
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

        observeVideoReadiness(playerItem: playerItem)
    }

    private func observeVideoReadiness(playerItem: AVPlayerItem) {
        if playerItem.status == .readyToPlay {
            mascotVideoReadyForDisplay = true
            return
        }
        videoReadyObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                guard status == .readyToPlay else { return }
                mascotVideoReadyForDisplay = true
            }
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
