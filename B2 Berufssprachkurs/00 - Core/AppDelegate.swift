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
        // Initialize AdMob
        AdManager.shared.initialize()
        
        // Request tracking permission (after a short delay to ensure app is fully loaded)
        TrackingManager.requestTrackingPermission()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

