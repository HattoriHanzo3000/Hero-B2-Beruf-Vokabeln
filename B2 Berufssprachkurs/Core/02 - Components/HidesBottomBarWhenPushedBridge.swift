//
//  HidesBottomBarWhenPushedBridge.swift
//  B2 Berufssprachkurs
//
//  Drives UIKit `hidesBottomBarWhenPushed` so the tab bar hides/shows in sync with
//  navigation pushes/pops. Using only `.toolbar(.hidden, for: .tabBar)` often shows
//  the tab bar one beat late after interactive pop, which makes tab items resize.
//

import SwiftUI
import UIKit

private struct HidesBottomBarWhenPushedBridge: UIViewControllerRepresentable {
    var hidesBottomBar: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        applyHidesBottomBarWhenPushed(from: uiViewController)
    }

    private func applyHidesBottomBarWhenPushed(from bridge: UIViewController) {
        func targetHost() -> UIViewController? {
            var current: UIViewController? = bridge.parent
            while let vc = current {
                let cls = NSStringFromClass(type(of: vc))
                if cls.contains("UIHostingController") {
                    return vc
                }
                current = vc.parent
            }
            return bridge.parent
        }

        func assign(to host: UIViewController) {
            guard host.hidesBottomBarWhenPushed != hidesBottomBar else { return }
            host.hidesBottomBarWhenPushed = hidesBottomBar
        }

        if let host = targetHost() {
            assign(to: host)
            return
        }
        DispatchQueue.main.async {
            if let host = targetHost() {
                assign(to: host)
            }
        }
    }
}

extension View {
    /// Prefer this over `.toolbar(.hidden, for: .tabBar)` for screens pushed from a tab’s
    /// `NavigationStack` so the system tab bar stays aligned with the transition.
    func hidesBottomBarWhenPushed(_ hides: Bool) -> some View {
        background(HidesBottomBarWhenPushedBridge(hidesBottomBar: hides))
    }
}
