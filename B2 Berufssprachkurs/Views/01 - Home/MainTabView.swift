//
//  MainTabView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit

enum TabItem: String, CaseIterable {
    case home = "home"
    case cockpit = "cockpit"
    case settings = "settings"
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .cockpit:
            return "gauge"
        case .settings:
            return "gear"
        }
    }
    
    var localizedTitle: String {
        return Localizable.string(self.rawValue)
    }
}

struct MainTabView: View {
    private let isPremiumPreviewOverride: Bool?

    @StateObject private var dataService: DataService
    @ObservedObject private var languageManager: LanguageManager
    @StateObject private var updateAlertManager: UpdateAlertManager
    @StateObject private var ratingManager: RatingManager
    @State private var selectedTab: TabItem = .home

    /// - Parameter isPremiumPreviewOverride: Pass `true` / `false` for canvas previews only; `nil` uses live subscription state.
    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        _dataService = StateObject(wrappedValue: DataService())
        _languageManager = ObservedObject(wrappedValue: LanguageManager.shared)
        _updateAlertManager = StateObject(wrappedValue: UpdateAlertManager.shared)
        _ratingManager = StateObject(wrappedValue: RatingManager.shared)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Shows learning stack cards
            NavigationStack {
                HomeTabView(isPremiumPreviewOverride: isPremiumPreviewOverride)
            }
            .tag(TabItem.home)
            .tabItem {
                Label(TabItem.home.localizedTitle, systemImage: TabItem.home.icon)
            }
            
            // Cockpit Tab
            NavigationStack {
                CockpitView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(TabItem.cockpit)
            .tabItem {
                Label(TabItem.cockpit.localizedTitle, systemImage: TabItem.cockpit.icon)
            }
            
            // Settings Tab
            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(TabItem.settings)
            .tabItem {
                Label(TabItem.settings.localizedTitle, systemImage: TabItem.settings.icon)
            }
        }
        .environmentObject(dataService)
        .environmentObject(LearningListsUIState.shared)
        .onAppear {
            setupLiquidGlassTabBar()
            // Track app launch for rating
            ratingManager.trackAppLaunch()
            // Check for update alert
            Task {
                await updateAlertManager.checkForUpdateAlert()
            }
        }
        .alert(Localizable.string(Localizable.updateAlertTitle), isPresented: $updateAlertManager.showUpdateAlert) {
            Button(Localizable.string(Localizable.updateNow)) {
                updateAlertManager.openAppStore()
            }
            Button(Localizable.string(Localizable.remindMeLater), role: .cancel) {
                updateAlertManager.remindMeLater()
            }
        } message: {
            Text(Localizable.string(Localizable.updateAlertMessage))
        }
        .overlay {
            // Rating prompt overlay
            if ratingManager.showRatingPrompt {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            ratingManager.remindLater()
                        }
                    
                    RatingPromptView()
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: ratingManager.showRatingPrompt)
            }
        }
    }
    
    private func setupLiquidGlassTabBar() {
        // Create liquid glass appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Use ultra-thin material for liquid glass effect
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Remove shadow for cleaner look
        appearance.shadowColor = .clear
        
        // Configure normal state with subtle colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Configure selected state with accent color
        let accentColor = UIColor(named: "AppGreen") ?? UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Apply to both standard and scroll edge appearances
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Enable translucency for liquid glass effect
        UITabBar.appearance().isTranslucent = true
        
        // Transparent background
        UITabBar.appearance().backgroundColor = .clear
        
        // Remove top border
        UITabBar.appearance().clipsToBounds = true
    }
}

/// Ensures full-tab previews use German strings (matches `LanguageManager` “Deutsch” option).
private struct MainTabPreviewHost: View {
    let isPremiumPreviewOverride: Bool

    init(isPremiumPreviewOverride: Bool) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        LanguageManager.shared.currentLanguage = "Deutsch"
    }

    var body: some View {
        MainTabView(isPremiumPreviewOverride: isPremiumPreviewOverride)
    }
}

#Preview("Main Tab - Free") {
    MainTabPreviewHost(isPremiumPreviewOverride: false)
}

#Preview("Main Tab - Premium") {
    MainTabPreviewHost(isPremiumPreviewOverride: true)
}

