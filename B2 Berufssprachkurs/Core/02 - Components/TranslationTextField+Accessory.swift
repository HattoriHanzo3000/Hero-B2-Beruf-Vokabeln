//
//  TranslationTextField+Accessory.swift
//  B2 Berufssprachkurs
//
//  Installs the floating "Liquid Glass" pill as a UITextView
//  inputAccessoryView, making the host UIToolbar fully transparent so only
//  the pill is visible hovering above the keyboard.
//

import SwiftUI
import UIKit

// MARK: - Layout Constants

private enum ToolbarAccessoryLayout {
    /// Pill height (44) + bottom gap (10) + breathing room above for shadow.
    static let toolbarHeight: CGFloat = 64
}

extension TranslationTextField.Coordinator {
    func installToolbarIfNeeded() {
        guard keyboardAccessoryHost == nil else { return }

        configureToolbarAppearance()

        let root = FloatingKeyboardAccessoryHostView(
            keyboardNav: parent.keyboardNavBridge,
            onPrevious: { [weak self] in
                guard let self else { return }
                HapticManager.shared.lightImpact()
                self.parent.keyboardNavBridge.onPrevious()
            },
            onNext: { [weak self] in
                guard let self else { return }
                HapticManager.shared.lightImpact()
                self.parent.keyboardNavBridge.onNext()
            },
            onDone: { [weak self] in
                guard let self else { return }
                HapticManager.shared.lightImpact()
                self.parent.keyboardNavBridge.onDismiss()
            }
        )

        let host = makeKeyboardAccessoryHost(root: root)
        embedHostInToolbar(host)
        keyboardAccessoryHost = host
    }

    // MARK: - Helpers

    /// Strips the default bar background so the pill appears to float.
    private func configureToolbarAppearance() {
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.isTranslucent = true
        toolbar.backgroundColor = .clear
        toolbar.barTintColor = .clear
        toolbar.tintColor = .clear
        toolbar.frame.size.height = ToolbarAccessoryLayout.toolbarHeight
    }

    private func makeKeyboardAccessoryHost(
        root: FloatingKeyboardAccessoryHostView
    ) -> UIHostingController<FloatingKeyboardAccessoryHostView> {
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.safeAreaRegions = []
        if #available(iOS 16.0, *) {
            host.sizingOptions = [.intrinsicContentSize]
        }
        return host
    }

    /// Pins the host view to the toolbar's full bounds so the pill can
    /// stretch edge-to-edge within its own horizontal insets.
    private func embedHostInToolbar(_ host: UIHostingController<FloatingKeyboardAccessoryHostView>) {
        toolbar.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: ToolbarAccessoryLayout.toolbarHeight
        )
        toolbar.items = []
        toolbar.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: toolbar.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
        ])
    }
}
