//
//  B2_BerufssprachkursApp.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

@main
struct B2_BerufssprachkursApp: App {
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
            .supportedOrientations(.portrait)
            .environmentObject(LanguageManager.shared)
            .environmentObject(TextSizeManager.shared)
            .environmentObject(AppearanceManager.shared)
        }
    }
}
