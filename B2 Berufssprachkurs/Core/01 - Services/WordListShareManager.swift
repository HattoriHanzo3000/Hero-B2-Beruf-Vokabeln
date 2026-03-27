//
//  WordListShareManager.swift
//  B2 Berufssprachkurs
//
//  Shared plain-text + PDF export for word lists (sections, favorites, My Words).
//

import SwiftUI
import UIKit

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
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
            } else {
                HapticManager.shared.heavyImpact()
                showPaywall = true
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.body)
                .foregroundColor(.primary)
        }
        .accessibilityLabel(Localizable.string(Localizable.share))
        .accessibilityHint(
            subscriptionManager.isPremiumActive
                ? "Share the words list"
                : "Share requires premium subscription"
        )
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
                ShareSheet(activityItems: [shareText(), pdfURL()])
            }
            .sheet(isPresented: showPaywall) {
                PaywallView()
            }
    }
}
