//
//  MainView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftData
import SwiftUI

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
    /// Tab to restore when the user dismisses search (system Cancel / X).
    @State private var sectionBeforeSearch: MainViewSection = .home

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
            Tab(value: MainViewSection.home) {
                NavigationStack {
                    HomeView(isPremiumPreviewOverride: isPremiumPreviewOverride)
                }
            } label: {
                Label(MainViewSection.home.localizedTitle, systemImage: MainViewSection.home.icon)
            }

            Tab(value: MainViewSection.cockpit) {
                NavigationStack {
                    CockpitView()
                        .navigationBarTitleDisplayMode(.inline)
                }
            } label: {
                Label(MainViewSection.cockpit.localizedTitle, systemImage: MainViewSection.cockpit.icon)
            }

            Tab(value: MainViewSection.search, role: .search) {
                NavigationStack {
                    GlobalSearchView(
                        selectedSection: $selectedSection,
                        sectionBeforeSearch: sectionBeforeSearch
                    )
                }
            }

            Tab(value: MainViewSection.settings) {
                NavigationStack {
                    SettingsView()
                        .navigationBarTitleDisplayMode(.inline)
                }
            } label: {
                Label(MainViewSection.settings.localizedTitle, systemImage: MainViewSection.settings.icon)
            }
        }
        .id(languageManager.currentLanguage)
        .environmentObject(dataService)
        .environmentObject(LearningListsUIState.shared)
        .onChange(of: selectedSection) { oldValue, newValue in
            if newValue == .search, oldValue != .search {
                sectionBeforeSearch = oldValue
            }
        }
        .onAppear {
            CustomWordEntry.renumberSortOrderIfNeeded(in: modelContext)
            dataService.updateUserCustomWords(from: customWordEntries)
            AppTabBarAppearance.applyLiquidGlassAppStyle()
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
            RatingPromptOverlay(ratingManager: ratingManager)
        }
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

#Preview("Main — Pro") {
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
