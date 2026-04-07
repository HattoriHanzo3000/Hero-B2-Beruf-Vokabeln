//
//  HeaderView+Mascot.swift
//  B2 Berufssprachkurs
//

import SwiftUI
import UIKit

struct MascotView: View {
    static let defaultSize: CGFloat = 100

    @State var showMascotGif = false
    /// Synchronous gate so rapid taps can’t double-enter before `showMascotGif` commits on the next run loop.
    @State var mascotPlaybackActive = false
    /// Cancels any pending “hide GIF” work when starting a new play (defensive).
    @State var mascotGifEndWorkItem: DispatchWorkItem?
    @State var autoPlayTask: Task<Void, Never>? = nil
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let autoPlayInterval: TimeInterval = 30.0
    var body: some View {
        ZStack {
            Image(staticMascotAssetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Self.defaultSize, height: Self.defaultSize)
                .opacity((showMascotGif && !reduceMotion) ? 0 : 1)

            AnimatedGIFView(
                gifName: gifMascotAssetName,
                contentMode: .scaleAspectFit,
                shouldAnimate: showMascotGif && !reduceMotion
            )
            .id(gifMascotAssetName)
            .frame(width: Self.defaultSize, height: Self.defaultSize)
            .opacity((showMascotGif && !reduceMotion) ? 1 : 0)
            .allowsHitTesting(false)
        }
        .frame(width: Self.defaultSize, height: Self.defaultSize)
        .scaleEffect(x: -1, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            playGifOnly()
        }
        .onAppear {
            startAutoPlay()
        }
        .onDisappear {
            autoPlayTask?.cancel()
            autoPlayTask = nil
        }
    }

    private var staticMascotAssetName: String {
        if colorScheme == .dark, UIImage(named: "MascotDark") != nil {
            return "MascotDark"
        }
        return "Mascot"
    }

    /// Dark mode uses `MascotDark.gif` when it is in the bundle; static art still follows `staticMascotAssetName` (PNG catalog).
    private var gifMascotAssetName: String {
        if colorScheme == .dark, GIFBundleLookup.resourceExists(resourceName: "MascotDark") {
            return "MascotDark"
        }
        return "Mascot"
    }

    /// Matches decoded GIF duration so the static image returns when the animation actually ends.
    private var gifPlaybackDuration: TimeInterval {
        GIFBundleLookup.totalAnimationDuration(forResourceName: gifMascotAssetName) ?? 1.0
    }

    func playGifOnly() {
        guard !reduceMotion else { return }
        guard !mascotPlaybackActive else { return }

        mascotGifEndWorkItem?.cancel()

        HapticManager.shared.lightImpact()
        mascotPlaybackActive = true
        showMascotGif = true

        let work = DispatchWorkItem {
            showMascotGif = false
            mascotPlaybackActive = false
            mascotGifEndWorkItem = nil
        }
        mascotGifEndWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + gifPlaybackDuration, execute: work)
    }

    func startAutoPlay() {
        autoPlayTask?.cancel()
        autoPlayTask = Task<Void, Never> { [reduceMotion] in
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(autoPlayInterval * 1_000_000_000))
                if Task.isCancelled { break }
                await MainActor.run {
                    playGifOnly()
                }
            }
        }
    }
}
