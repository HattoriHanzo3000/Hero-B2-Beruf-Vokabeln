//
//  EinburgerungAppIconView.swift
//  B2 Berufssprachkurs
//
//  Async App Store artwork for the Hero Einbürgerungstest row (loading, success, placeholder).
//

import SwiftUI

struct EinburgerungAppIconView: View {
    let artworkURL: URL?
    let lookupFinished: Bool

    private let size: CGFloat = 60
    private let cornerRadius: CGFloat = 13

    var body: some View {
        Group {
            if !lookupFinished {
                ProgressView()
                    .tint(.white.opacity(0.9))
                    .frame(width: size, height: size)
            } else if let artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white.opacity(0.9))
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        einburgerungStoreIconPlaceholder
                    @unknown default:
                        einburgerungStoreIconPlaceholder
                    }
                }
            } else {
                einburgerungStoreIconPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .accessibilityHidden(true)
    }

    /// Shown when lookup fails or image download fails — no local app-icon asset.
    private var einburgerungStoreIconPlaceholder: some View {
        Color.white.opacity(0.14)
    }
}
