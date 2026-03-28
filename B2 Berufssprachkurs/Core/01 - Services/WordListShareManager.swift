//
//  WordListShareManager.swift
//  B2 Berufssprachkurs
//
//  Shared plain-text + PDF export for word lists (sections, favorites, My Words).
//

import SwiftUI
import UIKit

// MARK: - Free tier (PDF share)

/// Non‑premium users get one successful PDF/text share; after that the paywall is shown.
enum WordListShareFreeTier {
    private static let countKey = "wordListFreePdfShareCount"
    private static let maxFreeShares = 1

    static var freeSharesUsed: Int {
        UserDefaults.standard.integer(forKey: countKey)
    }

    static var canShareFree: Bool {
        freeSharesUsed < maxFreeShares
    }

    /// Called when the system reports a completed share activity (Save, AirDrop, Messages, etc.).
    static func consumeFreeShareIfEligible() {
        guard !SubscriptionManager.shared.isPremiumActive else { return }
        guard freeSharesUsed < maxFreeShares else { return }
        UserDefaults.standard.set(freeSharesUsed + 1, forKey: countKey)
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    /// Invoked when the user finishes a share action successfully (`completed == true` in UIKit).
    var onShareCompleted: (() -> Void)?

    init(activityItems: [Any], onShareCompleted: (() -> Void)? = nil) {
        self.activityItems = activityItems
        self.onShareCompleted = onShareCompleted
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else { return }
            Task { @MainActor in
                onShareCompleted?()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Text & PDF rows

enum WordListShareManager {
    /// Plain-text body: optional `header` (e.g. title + blank lines), then one line per word.
    static func shareText(
        words: [Word],
        header: String,
        translationProvider: (Word) -> String
    ) -> String {
        var shareText = header
        for word in words {
            shareText += "\(word.german)"
            if let explanation = word.explanation, !explanation.isEmpty {
                shareText += " (\(explanation))"
            }
            let translation = translationProvider(word)
            if !translation.isEmpty {
                shareText += " - \(translation)"
            }
            shareText += "\n"
        }
        return shareText
    }

    static func wordDataForPDF(
        words: [Word],
        translationProvider: (Word) -> String
    ) -> [PDFGenerationService.WordData] {
        words.map { word in
            PDFGenerationService.WordData(
                german: word.german,
                example: word.example,
                explanation: word.explanation,
                translation: translationProvider(word),
                synonyms: word.synonyms
            )
        }
    }
}

// MARK: - Premium share toolbar control

struct WordListShareButton: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Binding var showShareSheet: Bool
    @Binding var showPaywall: Bool

    var body: some View {
        Button {
            if subscriptionManager.isPremiumActive {
                HapticManager.shared.lightImpact()
                showShareSheet = true
            } else if WordListShareFreeTier.canShareFree {
                HapticManager.shared.lightImpact()
                showShareSheet = true
            } else {
                HapticManager.shared.heavyImpact()
                showPaywall = true
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .navigationBarSymbolStyle()
                .foregroundColor(.primary)
        }
        .accessibilityLabel(Localizable.string(Localizable.share))
        .accessibilityHint(accessibilityHintText)
    }

    private var accessibilityHintText: String {
        if subscriptionManager.isPremiumActive {
            return "Share the words list as text and PDF"
        }
        if WordListShareFreeTier.canShareFree {
            return "Share once for free, then premium is required"
        }
        return "Premium subscription required to share"
    }
}

// MARK: - Sheets

extension View {
    /// Share sheet (text + PDF URL) and paywall for non‑premium users.
    func wordListPremiumShareSheets(
        showShareSheet: Binding<Bool>,
        showPaywall: Binding<Bool>,
        shareText: @escaping () -> String,
        pdfURL: @escaping () -> URL
    ) -> some View {
        self
            .sheet(isPresented: showShareSheet) {
                ShareSheet(activityItems: [shareText(), pdfURL()]) {
                    WordListShareFreeTier.consumeFreeShareIfEligible()
                }
            }
            .sheet(isPresented: showPaywall) {
                PaywallView()
            }
    }
}
