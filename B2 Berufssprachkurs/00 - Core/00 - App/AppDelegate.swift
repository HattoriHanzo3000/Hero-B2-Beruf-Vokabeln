//
//  AppDelegate.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize RevenueCat SDK early
        // This will configure RevenueCat and start syncing customer info
        Task { @MainActor in
            _ = RevenueCatService.shared
        }
        
        // Initialize SubscriptionManager to check subscription status early
        Task { @MainActor in
            await SubscriptionManager.shared.loadProducts()
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

