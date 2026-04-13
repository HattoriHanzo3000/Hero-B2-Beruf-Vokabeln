//
//  ShareView.swift
//  B2 Berufssprachkurs
//
//  Share screen with App Store QR code and share sheet action.
//  Created: 16.12.25.
//

import SwiftUI

// MARK: - Screen

struct ShareView: View {
    // MARK: State

    @State private var showShareSheet = false

    // MARK: Derived Data

    private var appStoreURL: String { AppStoreService.defaultListingURL }

    private var shareText: String {
        let appName = Localizable.string(Localizable.aboutThisApp)
        return "\(appName)\n\(appStoreURL)"
    }

    // MARK: View Layout

    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView {
                VStack(spacing: 24) {
                    QRCodeView(url: appStoreURL)
                        .frame(width: 280, height: 280)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.top, 20)

                    Text(Localizable.string(Localizable.shareScreenFooter))
                        .font(.system(.body, design: .default, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer(minLength: 24)
                }
                .padding(.vertical, 20)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
        .navigationTitle(Localizable.string(Localizable.share))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.lightImpact()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .navigationBarSymbolStyle()
                        .foregroundColor(.primary)
                }
                .accessibilityLabel(Text(Localizable.string(Localizable.share)))
                .accessibilityHint(Text(Localizable.string(Localizable.shareToolbarA11yHint)))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let appStoreLink = URL(string: appStoreURL) {
                ShareSheet(activityItems: [shareText, appStoreLink])
            } else {
                ShareSheet(activityItems: [shareText])
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShareView()
    }
}
