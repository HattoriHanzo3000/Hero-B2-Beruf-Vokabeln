//
//  NotificationSoftPromptView.swift
//  B2 Berufssprachkurs
//
//  Pre-permission notification prompt component shown before system dialog.
//  Created: 09.12.25.
//

import SwiftUI

// MARK: - Component

/// In-app prompt shown before requesting system notification permission.
struct NotificationSoftPromptView: View {
    // MARK: Callbacks

    var onAllow: () -> Void
    var onAskMeLater: () -> Void
    var onNoThanks: () -> Void

    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.colorScheme) private var colorScheme

    // MARK: View Layout

    var body: some View {
        VStack(spacing: 0) {
            Image("Mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(.top, 32)
                .padding(.bottom, 20)
                .accessibilityHidden(true)

            Text(Localizable.string(Localizable.notificationSoftPromptTitle))
                .font(.system(.title2, design: .default).weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            Text(Localizable.string(Localizable.notificationSoftPromptMessage))
                .font(.system(.body, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

            VStack(spacing: 12) {
                Button {
                    HapticManager.shared.mediumImpact()
                    onAllow()
                } label: {
                    Text(Localizable.string(Localizable.notificationSoftPromptAllow))
                        .font(.system(.headline, design: .default).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
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
                .accessibilityHint(Localizable.string(Localizable.notificationSoftPromptAllowA11yHint))

                Button {
                    HapticManager.shared.lightImpact()
                    onAskMeLater()
                } label: {
                    Text(Localizable.string(Localizable.notificationSoftPromptAskMeLater))
                        .font(.system(.body, design: .default).weight(.medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(colorScheme == .light ? Color(.systemGray6) : Color(.systemGray5))
                        )
                }
                .accessibilityHint(Localizable.string(Localizable.notificationSoftPromptAskMeLaterA11yHint))

                Button {
                    HapticManager.shared.lightImpact()
                    onNoThanks()
                } label: {
                    Text(Localizable.string(Localizable.notificationSoftPromptNoThanks))
                        .font(.system(.body, design: .default))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                }
                .accessibilityHint(Localizable.string(Localizable.notificationSoftPromptNoThanksA11yHint))
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

private struct NotificationSoftPromptPreviewHost: View {
    init(language: String) {
        LanguageManager.shared.currentLanguage = language
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            Color.black.opacity(0.32)
                .ignoresSafeArea()

            NotificationSoftPromptView(
                onAllow: {},
                onAskMeLater: {},
                onNoThanks: {}
            )
        }
    }
}

#Preview("English") {
    NotificationSoftPromptPreviewHost(language: "English")
}

#Preview("Deutsch") {
    NotificationSoftPromptPreviewHost(language: "Deutsch")
}
