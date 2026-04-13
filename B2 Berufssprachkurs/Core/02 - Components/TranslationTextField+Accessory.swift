//
//  TranslationTextField+Accessory.swift
//  B2 Berufssprachkurs
//

import SwiftUI
import UIKit

extension TranslationTextField.Coordinator {
    func installToolbarIfNeeded() {
        guard keyboardAccessoryHost == nil else { return }

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
        let group = UIBarButtonItem(customView: host.view)
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flex, group]
        keyboardAccessoryHost = host
    }

    private func makeKeyboardAccessoryHost(root: FloatingKeyboardAccessoryHostView) -> UIHostingController<FloatingKeyboardAccessoryHostView> {
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.safeAreaRegions = []
        if #available(iOS 16.0, *) {
            host.sizingOptions = [.intrinsicContentSize]
        }
        NSLayoutConstraint.activate([
            host.view.heightAnchor.constraint(equalToConstant: 44),
        ])
        return host
    }
}
