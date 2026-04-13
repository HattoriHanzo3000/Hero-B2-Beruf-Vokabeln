//
//  SettingsLegalWebSheetView.swift
//  B2 Berufssprachkurs
//
//  Safari-based web sheet for legal and external Settings links.
//  Created: 24.11.25.
//

import SafariServices
import SwiftUI

// MARK: - Component

struct SettingsLegalWebSheetView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Legal Web Sheet") {
    SettingsLegalWebSheetView(url: AppExternalLinks.companyWebsite)
}

