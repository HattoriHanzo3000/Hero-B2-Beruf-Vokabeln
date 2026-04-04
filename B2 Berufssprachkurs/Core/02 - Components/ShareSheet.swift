//
//  ShareSheet.swift
//  B2 Berufssprachkurs
//
//  UIKit bridge for `UIActivityViewController`.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
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
