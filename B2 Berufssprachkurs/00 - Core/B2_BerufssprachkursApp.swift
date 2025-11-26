//
//  B2_BerufssprachkursApp.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

// View modifier to lock orientation to portrait
struct PortraitOrientationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                AppDelegate.orientationLock = .portrait
            }
    }
}

extension View {
    func portraitOrientation() -> some View {
        self.modifier(PortraitOrientationModifier())
    }
}

// AppDelegate to handle orientation and AdMob initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize AdMob
        AdManager.shared.initialize()
        
        // Request tracking permission (after a short delay to ensure app is fully loaded)
        TrackingManager.requestTrackingPermission()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct B2_BerufssprachkursApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("textSizePreference") private var textSizePreference: String = "Large"
    @AppStorage("appearancePreference") private var appearancePreference: String = "System"
    @AppStorage("hasSeenWelcomeVideo") private var hasSeenWelcomeVideo: Bool = false
    
    private var colorScheme: ColorScheme? {
        switch appearancePreference {
        case "Light":
            return .light
        case "Dark":
            return .dark
        case "System":
            return nil // nil means use system default
        default:
            return nil
        }
    }
    
    private var dynamicTypeSize: DynamicTypeSize {
        switch textSizePreference {
        case "Extra Small":
            return .xSmall
        case "Small":
            return .small
        case "Medium":
            return .medium
        case "Large":
            return .large
        case "Extra Large":
            return .xLarge
        case "XX Large":
            return .xxLarge
        case "XXX Large":
            return .xxxLarge
        default:
            return .large
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenWelcomeVideo {
                    WelcomeVideoView(hasSeenWelcomeVideo: $hasSeenWelcomeVideo)
                } else {
                    MainTabView()
                }
            }
            // Apply dynamic type size from user preference
            .dynamicTypeSize(dynamicTypeSize)
            // Apply appearance preference (Light/Dark/System)
            .preferredColorScheme(colorScheme)
            // Lock orientation to portrait only
            .portraitOrientation()
            .environmentObject(LanguageManager.shared)
            .environmentObject(TextSizeManager.shared)
            .environmentObject(AppearanceManager.shared)
        }
    }
}
