//
//  AppDelegate.swift
//  B2 Berufssprachkurs
//
//  UIKit lifecycle bridge for startup, deep links, and orientation policy.
//  Created: 24.03.26.
//

import UIKit

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: Orientation

    /// App-wide orientation lock.
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    // MARK: App Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task { @MainActor in
            _ = RevenueCatService.shared
            _ = SubscriptionManager.shared
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppGroupQuickAddBridge.consumePendingQuickAddIfNeeded()
    }

    // MARK: Deep Links

    /// Handles incoming deep links and forwards routing to `AppDeepLinkRouter`.
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        DispatchQueue.main.async {
            AppDeepLinkRouter.shared.handle(url: url)
        }
        return true
    }
    
    // MARK: Interface Orientation

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

