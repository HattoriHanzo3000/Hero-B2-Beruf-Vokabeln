//
//  PaywallLegalAgreementSection.swift
//  B2 Berufssprachkurs
//
//  Subscription terms caption + markdown agreement line with in-app legal URLs.
//

import SwiftUI

/// Sheet item for `SettingsLegalWebSheetView`.
struct PaywallLegalDocument: Identifiable {
    let url: URL
    var id: URL { url }
}

enum PaywallLegalLinks {
    static func subscriptionTermsCaption(forProductId productId: String) -> String {
        if PaywallProductID.usesLifetimeTerms(productIdentifier: productId) {
            return Localizable.string(Localizable.subscriptionTermsLifetime)
        }
        return Localizable.string(Localizable.subscriptionTerms)
    }

    static func agreementAttributedString() -> AttributedString {
        let source = Localizable.string(Localizable.subscriptionTermsAgreementLine)
        let baseFont = Font.system(.caption2, design: .default).weight(.regular)
        let linkFont = Font.system(.caption2, design: .default).weight(.semibold)
        let baseColor = Color.white.opacity(0.85)

        guard var attributed = try? AttributedString(markdown: source) else {
            var plain = AttributedString(source)
            plain.font = baseFont
            plain.foregroundColor = baseColor
            return plain
        }

        attributed.font = baseFont
        attributed.foregroundColor = baseColor

        for run in attributed.runs {
            if run.link != nil {
                attributed[run.range].font = linkFont
                attributed[run.range].foregroundColor = baseColor
            }
        }

        return attributed
    }

    static func handleOpenURL(_ url: URL, presentingLegalURL: Binding<URL?>) -> OpenURLAction.Result {
        HapticManager.shared.lightImpact()
        switch url.absoluteString {
        case AppExternalLinks.subscriptionTermsLinkScheme:
            presentingLegalURL.wrappedValue = AppExternalLinks.legalTermsOfUse
            return .handled
        case AppExternalLinks.subscriptionPrivacyLinkScheme:
            presentingLegalURL.wrappedValue = AppExternalLinks.legalPrivacyPolicy
            return .handled
        default:
            return .systemAction(url)
        }
    }
}

struct PaywallLegalAgreementSection: View {
    let selectedProductId: String
    @Binding var presentingLegalURL: URL?

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(PaywallLegalLinks.subscriptionTermsCaption(forProductId: selectedProductId))
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Text(PaywallLegalLinks.agreementAttributedString())
                    .fontDesign(.default)
                    .multilineTextAlignment(.center)
                    .environment(\.openURL, OpenURLAction { url in
                        PaywallLegalLinks.handleOpenURL(url, presentingLegalURL: $presentingLegalURL)
                    })
            }
            .fontDesign(.default)
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
    }
}
