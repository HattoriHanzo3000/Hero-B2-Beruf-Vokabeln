//
//  MainView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData
import UIKit

/// Identifies which root area is selected in the main `TabView` (home, cockpit, settings). Raw values match `Localizable` keys.
enum MainViewSection: String, CaseIterable {
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
        Localizable.string(self.rawValue)
    }
}

struct MainView: View {
    private let isPremiumPreviewOverride: Bool?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\CustomWordEntry.sortIndex, order: .forward),
        SortDescriptor(\CustomWordEntry.createdAt, order: .forward)
    ]) private var customWordEntries: [CustomWordEntry]
    @StateObject private var dataService: DataService
    @ObservedObject private var languageManager: LanguageManager
    @StateObject private var updateAlertManager: UpdateAlertManager
    @StateObject private var ratingManager: RatingManager
    @State private var selectedSection: MainViewSection = .home

    /// - Parameter isPremiumPreviewOverride: Pass `true` / `false` for canvas previews only; `nil` uses live subscription state.
    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        _dataService = StateObject(wrappedValue: DataService())
        _languageManager = ObservedObject(wrappedValue: LanguageManager.shared)
        _updateAlertManager = StateObject(wrappedValue: UpdateAlertManager.shared)
        _ratingManager = StateObject(wrappedValue: RatingManager.shared)
    }

    var body: some View {
        TabView(selection: $selectedSection) {
            NavigationStack {
                HomeView(isPremiumPreviewOverride: isPremiumPreviewOverride)
            }
            .tag(MainViewSection.home)
            .tabItem {
                Label(MainViewSection.home.localizedTitle, systemImage: MainViewSection.home.icon)
            }

            NavigationStack {
                CockpitView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(MainViewSection.cockpit)
            .tabItem {
                Label(MainViewSection.cockpit.localizedTitle, systemImage: MainViewSection.cockpit.icon)
            }

            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(MainViewSection.settings)
            .tabItem {
                Label(MainViewSection.settings.localizedTitle, systemImage: MainViewSection.settings.icon)
            }
        }
        .environmentObject(dataService)
        .environmentObject(LearningListsUIState.shared)
        .onAppear {
            CustomWordEntry.renumberSortOrderIfNeeded(in: modelContext)
            dataService.updateUserCustomWords(from: customWordEntries)
            setupLiquidGlassTabBar()
            ratingManager.trackAppLaunch()
            Task {
                await updateAlertManager.checkForUpdateAlert()
            }
        }
        .onChange(of: customWordEntries) { _, newValue in
            dataService.updateUserCustomWords(from: newValue)
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
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.shadowColor = .clear

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        let accentColor = UIColor(named: "AppGreen") ?? UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = .clear
        UITabBar.appearance().clipsToBounds = true
    }
}

private struct MainViewPreviewHost: View {
    let isPremiumPreviewOverride: Bool
    /// `""` restores default Word of the Day (section **1A**). A single id (e.g. `VERBEN_mit`) limits WOTD to that section for previews.
    let wordOfTheDaySelectedSectionIds: String

    init(
        isPremiumPreviewOverride: Bool,
        wordOfTheDaySelectedSectionIds: String = ""
    ) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        self.wordOfTheDaySelectedSectionIds = wordOfTheDaySelectedSectionIds
        LanguageManager.shared.currentLanguage = "Deutsch"
        UserDefaults.standard.set(
            wordOfTheDaySelectedSectionIds,
            forKey: "wordOfTheDaySelectedSections"
        )
    }

    var body: some View {
        MainView(isPremiumPreviewOverride: isPremiumPreviewOverride)
    }
}

#Preview("Main — Free") {
    MainViewPreviewHost(isPremiumPreviewOverride: false)
}

#Preview("Main — Premium") {
    MainViewPreviewHost(isPremiumPreviewOverride: true)
}

#Preview("Main — WOTD Verben mit Präpositionen") {
    MainViewPreviewHost(
        isPremiumPreviewOverride: true,
        wordOfTheDaySelectedSectionIds: "VERBEN_mit"
    )
}

#Preview("Main — WOTD Adjektive mit Präpositionen") {
    MainViewPreviewHost(
        isPremiumPreviewOverride: true,
        wordOfTheDaySelectedSectionIds: "ADJEKTIVE_mit"
    )
}
