//
//  AdvertisementView.swift
//  B2 Berufssprachkurs
//
//  Promotional sheet showcasing other Hero app offerings.
//  Created: 01.04.26.
//

import SwiftUI
import AVFoundation

// MARK: - Screen

struct AdvertisementView: View {
    // MARK: State

    @Environment(\.dismiss) private var dismiss
    @State private var einburgerungArtworkURL: URL?
    @State private var einburgerungArtworkLookupFinished = false
    @State private var flagPlayer: AVPlayer?
    @State private var flagEndObserver: NSObjectProtocol?
    @State private var flagReplayTask: Task<Void, Never>?
    @State private var flagPlayerAssetName: String?

    // MARK: View Layout

    var body: some View {
        NavigationStack {
            ZStack {
                PaywallBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .center, spacing: 10) {
                            Text(Localizable.string(Localizable.advertisementHeroLeadTitle))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .italic()
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            flagAnimationView
                                .frame(width: 200, height: 200)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)

                            Text(Localizable.string(Localizable.advertisementHeroLeadSubtitle))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.88))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)

                        einburgerungAppRow
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .background(Color.clear)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            prepareFlagPlayerIfNeeded()
        }
        .onDisappear {
            cleanupFlagPlayer()
        }
        .task {
            einburgerungArtworkURL = await AppStoreArtworkLookup.artworkURL(
                appID: HeroEinburgerungAppStore.iTunesLookupAppID
            )
            einburgerungArtworkLookupFinished = true
        }
    }

    // MARK: Components

    private var einburgerungAppRow: some View {
        Button {
            HeroEinburgerungStorePresentation.present()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                EinburgerungAppIconView(
                    artworkURL: einburgerungArtworkURL,
                    lookupFinished: einburgerungArtworkLookupFinished
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(Localizable.string(Localizable.advertisementEinburgerungAppTitle))
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    Text(Localizable.string(Localizable.advertisementEinburgerungAppSubtitle))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            "\(Localizable.string(Localizable.advertisementEinburgerungAppTitle)). \(Localizable.string(Localizable.advertisementEinburgerungAppSubtitle))"
        )
    }

    private var flagAnimationView: some View {
        Group {
            if let flagPlayer {
                AlphaVideoPlayerView(player: flagPlayer, videoGravity: .resizeAspect)
                    .id(flagVideoAssetName)
                    .allowsHitTesting(false)
                    .onAppear {
                        flagPlayer.play()
                    }
            } else {
                AnimatedGIFView(
                    gifName: "HeroFlag",
                    contentMode: .scaleAspectFit,
                    shouldAnimate: true,
                    loops: true
                )
                .id("HeroFlag")
                .allowsHitTesting(false)
            }
        }
    }

    private var flagVideoAssetName: String {
        "MascotFlag"
    }

    private var flagVideoURL: URL? {
        Bundle.main.url(forResource: flagVideoAssetName, withExtension: "mov")
        ?? Bundle.main.url(forResource: flagVideoAssetName, withExtension: "mp4")
    }

    private func prepareFlagPlayerIfNeeded() {
        guard let url = flagVideoURL else {
            cleanupFlagPlayer()
            return
        }

        if flagPlayerAssetName == flagVideoAssetName, flagPlayer != nil {
            flagPlayer?.play()
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true

        if let flagEndObserver {
            NotificationCenter.default.removeObserver(flagEndObserver)
            self.flagEndObserver = nil
        }

        flagEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            scheduleFlagReplay(for: player)
        }

        flagPlayer = player
        flagPlayerAssetName = flagVideoAssetName
        player.play()
    }

    private func scheduleFlagReplay(for player: AVPlayer?) {
        flagReplayTask?.cancel()
        flagReplayTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled, let player else { return }
                await player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                player.play()
            } catch {
                // Cancellation is expected when the sheet disappears.
            }
        }
    }

    private func cleanupFlagPlayer() {
        flagReplayTask?.cancel()
        flagReplayTask = nil

        if let flagEndObserver {
            NotificationCenter.default.removeObserver(flagEndObserver)
            self.flagEndObserver = nil
        }

        flagPlayer?.pause()
        flagPlayer?.replaceCurrentItem(with: nil)
        flagPlayer = nil
        flagPlayerAssetName = nil
    }
}

// MARK: - Preview

#Preview {
    AdvertisementView()
}
