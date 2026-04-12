//
//  AdvertisementView.swift
//  B2 Berufssprachkurs
//
//  Sheet for cockpit “More from Hero” — paywall-style green gradient. The Einbürgerungstest app icon is
//  loaded from the App Store (iTunes Lookup + AsyncImage), not from a bundled catalog image.
//

import SwiftUI

struct AdvertisementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var einburgerungArtworkURL: URL?
    @State private var einburgerungArtworkLookupFinished = false

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

                            AnimatedGIFView(
                                gifName: "HeroFlag",
                                contentMode: .scaleAspectFit,
                                shouldAnimate: true,
                                loops: true
                            )
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
        .task {
            einburgerungArtworkURL = await AppStoreArtworkLookup.artworkURL(
                appID: HeroEinburgerungAppStore.iTunesLookupAppID
            )
            einburgerungArtworkLookupFinished = true
        }
    }

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
}

#Preview {
    AdvertisementView()
}
