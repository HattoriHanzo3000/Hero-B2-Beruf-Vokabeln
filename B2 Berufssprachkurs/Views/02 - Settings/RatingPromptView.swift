//
//  RatingPromptView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct RatingPromptView: View {
    @ObservedObject private var ratingManager = RatingManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Mascot image at the top
            Image("MascotLaunch")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(.top, 32)
                .padding(.bottom, 20)

            // Title
            Text(Localizable.string(Localizable.ratingTitle))
                .font(.system(.title2, design: .default).weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            // Subtitle
            Text(Localizable.string(Localizable.ratingSubtitle))
                .font(.system(.body, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

            // Buttons
            VStack(spacing: 12) {
                // Rate button (primary)
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    ratingManager.requestAppReview()
                }) {
                    Text(Localizable.string(Localizable.ratingRateButton))
                        .font(.system(.headline, design: .default).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color("AppGreen"),
                                    Color("AppBlue")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color("AppGreen").opacity(0.3), radius: 8, x: 0, y: 4)
                }

                // Later button (secondary)
                Button(action: {
                    HapticManager.shared.lightImpact()
                    ratingManager.remindLater()
                }) {
                    Text(Localizable.string(Localizable.ratingLaterButton))
                        .font(.system(.body, design: .default).weight(.medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(colorScheme == .light ? Color(.systemGray6) : Color(.systemGray5))
                        )
                }

                // No thanks button (tertiary)
                Button(action: {
                    HapticManager.shared.lightImpact()
                    ratingManager.disableRatingRequests()
                }) {
                    Text(Localizable.string(Localizable.ratingNoThanksButton))
                        .font(.system(.body, design: .default))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .id(languageManager.currentLanguage)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 24)
    }
}

// MARK: - Previews

private struct RatingPromptPreviewHost: View {
    init(language: String) {
        LanguageManager.shared.currentLanguage = language
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            RatingPromptView()
        }
    }
}

#Preview("English") {
    RatingPromptPreviewHost(language: "English")
}

#Preview("Deutsch") {
    RatingPromptPreviewHost(language: "Deutsch")
}
