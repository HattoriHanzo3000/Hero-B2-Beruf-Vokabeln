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
    case premium = "premium"
    case cockpit = "cockpit"
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .premium:
            return "crown.fill"
        case .cockpit:
            return "gauge"
        }
    }
    
    var localizedTitle: String {
        return Localizable.string(self.rawValue)
    }
}

struct MainTabView: View {
    @StateObject private var dataService = DataService()
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var selectedTab: TabItem = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Shows learning stack cards
            NavigationStack {
                HomeTabView()
            }
            .tag(TabItem.home)
            .tabItem {
                Label(TabItem.home.localizedTitle, systemImage: TabItem.home.icon)
            }
            .id("homeTab_\(languageManager.currentLanguage)")
            
            // Premium Tab
            NavigationStack {
                PremiumView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(TabItem.premium)
            .tabItem {
                Label(TabItem.premium.localizedTitle, systemImage: TabItem.premium.icon)
            }
            .id("premiumTab_\(languageManager.currentLanguage)")
            
            // Cockpit Tab
            NavigationStack {
                CockpitView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(TabItem.cockpit)
            .tabItem {
                Label(TabItem.cockpit.localizedTitle, systemImage: TabItem.cockpit.icon)
            }
            .id("cockpitTab_\(languageManager.currentLanguage)")
        }
        .id("tabView_\(languageManager.currentLanguage)")
        .environmentObject(dataService)
        .onAppear {
            setupLiquidGlassTabBar()
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

#Preview {
    MainTabView()
}

