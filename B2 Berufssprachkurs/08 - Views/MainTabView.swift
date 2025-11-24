//
//  MainTabView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit

enum TabItem: String, CaseIterable {
    case words = "words"
    case verbs = "verbs"
    case settings = "settings"
    
    var icon: String {
        switch self {
        case .words:
            return "book.fill"
        case .verbs:
            return "figure.run"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var localizedTitle: String {
        return Localizable.string(self.rawValue)
    }
}

struct MainTabView: View {
    @StateObject private var dataService = DataService()
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedTab: TabItem = .words
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Words Tab - Shows LectionsListView
            NavigationStack {
                HomeView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(TabItem.words)
            .tabItem {
                Label(TabItem.words.localizedTitle, systemImage: TabItem.words.icon)
            }
            
            // Verbs Tab - Shows Verbs with Prepositions
            NavigationStack {
                VerbsView(dataService: dataService)
            }
            .tag(TabItem.verbs)
            .tabItem {
                Label(TabItem.verbs.localizedTitle, systemImage: TabItem.verbs.icon)
            }
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tag(TabItem.settings)
            .tabItem {
                Label(TabItem.settings.localizedTitle, systemImage: TabItem.settings.icon)
            }
        }
        .environmentObject(dataService)
        .onAppear {
            setupLiquidGlassTabBar()
        }
        .id(languageManager.currentLanguage) // Force refresh when language changes
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

