//
//  UIApplication+TopMostViewController.swift
//  B2 Berufssprachkurs
//
//  Topmost view controller for presenting UIKit from SwiftUI.
//

import UIKit

extension UIApplication {
    @MainActor
    var b2_topMostViewController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let windowScene = scene else { return nil }
        let window = windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first
        guard let root = window?.rootViewController else { return nil }
        return Self.b2_resolveTopMostViewController(from: root)
    }

    private static func b2_resolveTopMostViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return b2_resolveTopMostViewController(from: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return b2_resolveTopMostViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return b2_resolveTopMostViewController(from: selected)
        }
        return root
    }
}
