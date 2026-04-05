//
//  WordListShareManager.swift
//  B2 Berufssprachkurs
//
//  Shared plain-text + PDF export for word lists (sections, favorites, My Words).
//

import os
import SwiftUI
import UIKit

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

// MARK: - Print (PDF)

enum WordListPrintPresenter {
    static func present(pdfURL: URL, jobName: String) {
        guard FileManager.default.fileExists(atPath: pdfURL.path) else { return }
        let printController = UIPrintInteractionController.shared
        printController.printPageRenderer = nil
        printController.printFormatter = nil
        printController.printingItems = nil

        let printInfo = UIPrintInfo.printInfo()
        printInfo.jobName = jobName
        printInfo.outputType = .general
        printInfo.duplex = .none
        printInfo.orientation = .portrait

        printController.printInfo = printInfo
        printController.printingItem = pdfURL
        printController.showsPaperOrientation = true
        printController.showsNumberOfCopies = true
        printController.showsPaperSelectionForLoadedPapers = true

        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first,
                  let rootVC = window.rootViewController else {
                printController.present(animated: true, completionHandler: nil)
                return
            }
            let host = topMostViewController(from: rootVC)
            let rect = CGRect(x: host.view.bounds.midX, y: host.view.bounds.midY, width: 1, height: 1)
            printController.present(from: rect, in: host.view, animated: true, completionHandler: nil)
        } else {
            printController.present(animated: true, completionHandler: nil)
        }
    }

    private static func topMostViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topMostViewController(from: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topMostViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(from: selected)
        }
        return root
    }
}

/// Toolbar control: opens the system print panel with a generated PDF (available for all users).
struct WordListPrintButton: View {
    var isEnabled: Bool = true
    var pdfURL: () throws -> URL
    var jobName: String

    var body: some View {
        Button {
            guard isEnabled else { return }
            let url: URL
            do {
                url = try pdfURL()
            } catch {
                AppLog.pdf.error("Failed to generate PDF: \(error.localizedDescription, privacy: .public)")
                return
            }
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            HapticManager.shared.lightImpact()
            WordListPrintPresenter.present(pdfURL: url, jobName: jobName)
        } label: {
            Image(systemName: "printer")
                .navigationBarSymbolStyle()
                .foregroundColor(.primary)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(Localizable.string(Localizable.myWordsPrint))
        .accessibilityHint(Localizable.string(Localizable.wordListPrintA11yHint))
    }
}
