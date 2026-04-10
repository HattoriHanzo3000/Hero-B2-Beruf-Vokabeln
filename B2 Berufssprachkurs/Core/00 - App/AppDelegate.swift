//
//  AppDelegate.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    /// App-wide orientation; change at runtime if a specific flow needs landscape (e.g. fullscreen video).
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure RevenueCat before any code uses Purchases; then touch SubscriptionManager so its
        // init schedules entitlement sync + loadProducts (avoid duplicate loadProducts vs that path).
        Task { @MainActor in
            _ = RevenueCatService.shared
            _ = SubscriptionManager.shared
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppGroupQuickAddBridge.consumePendingQuickAddIfNeeded()
    }

    /// Widget `OpenURLIntent` / Lock Screen taps often arrive here; may also mirror `onOpenURL`. Dedup is in `AppDeepLinkRouter`.
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
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

