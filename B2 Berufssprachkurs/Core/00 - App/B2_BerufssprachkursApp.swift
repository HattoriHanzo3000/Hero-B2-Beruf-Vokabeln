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

@main
struct B2_BerufssprachkursApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("appearancePreference") private var appearancePreference: String = "System"
    @AppStorage("hasSeenWelcomeVideo") private var hasSeenWelcomeVideo: Bool = false
    
    init() {
        // RevenueCat is initialized in AppDelegate
    }
    
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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenWelcomeVideo {
                    WelcomeVideoView(hasSeenWelcomeVideo: $hasSeenWelcomeVideo)
                } else {
                    MainTabView()
                }
            }
            // Apply appearance preference (Light/Dark/System)
            .preferredColorScheme(colorScheme)
            // Lock orientation to portrait only
            .portraitOrientation()
            .environmentObject(LanguageManager.shared)
            .environmentObject(AppearanceManager.shared)
        }
    }
}
