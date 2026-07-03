//
//  MainView.swift
//  B2 Berufssprachkurs
//
//  Root tab container coordinating app-wide navigation and deep links.
//  Created: 24.11.25.
//

import SwiftData
import SwiftUI

// MARK: - Root Screen

struct MainView: View {
    // MARK: Configuration

    private let isPremiumPreviewOverride: Bool?

    // MARK: State & Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\CustomWordEntry.sortIndex, order: .forward),
        SortDescriptor(\CustomWordEntry.createdAt, order: .forward)
    ]) private var customWordEntries: [CustomWordEntry]
    @StateObject private var dataService: DataService
    @ObservedObject private var languageManager: LanguageManager
    @ObservedObject private var updateAlertManager = UpdateAlertManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @EnvironmentObject private var deepLinkRouter: AppDeepLinkRouter
    @State private var selectedSection: MainViewSection = .home
    /// Tracks where Search should return after system dismiss.
    @State private var sectionBeforeSearch: MainViewSection = .home
    /// Controls deep-link quick add presentation.
    @State private var showQuickAddMyWordSheet = false
    @State private var showQuickAddMyWordProAlert = false
    @State private var pendingQuickAddAfterEntitlementSync = false
    @State private var showMyWordsStudy = false
    @State private var pendingMyWordsStudyAfterEntitlementSync = false

    // MARK: Initialization

    /// Pass `true` or `false` for previews; `nil` uses live subscription state.
    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        _dataService = StateObject(wrappedValue: DataService())
        _languageManager = ObservedObject(wrappedValue: LanguageManager.shared)
    }

    // MARK: Derived Data

    private var isPremiumActionAuthorized: Bool {
        if let isPremiumPreviewOverride {
            return isPremiumPreviewOverride
        }
        return subscriptionManager.isPremiumAuthorizationGranted
    }

    // MARK: View Layout

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
            } else if newValue != .search {
                // Keeps Search return behavior consistent with the current tab.
                sectionBeforeSearch = newValue
            }
        }
        .onAppear {
            dataService.attachSwiftDataPersistence(modelContext)
            CustomWordEntry.renumberSortOrderIfNeeded(in: modelContext)
            dataService.updateUserCustomWords(from: customWordEntries)
            AppTabBarAppearance.applyLiquidGlassAppStyle()
            RatingManager.shared.recordAppLaunch()
            Task {
                await updateAlertManager.checkForUpdateAlert()
            }
        }
        .onChange(of: customWordEntries) { _, newValue in
            dataService.updateUserCustomWords(from: newValue)
        }
        .onChange(of: subscriptionManager.hasCompletedInitialSubscriptionSync) { _, hasCompleted in
            guard hasCompleted else { return }
            if pendingQuickAddAfterEntitlementSync {
                pendingQuickAddAfterEntitlementSync = false
                presentQuickAddGateOutcome()
            }
            if pendingMyWordsStudyAfterEntitlementSync {
                pendingMyWordsStudyAfterEntitlementSync = false
                presentMyWordsStudyGateOutcome()
            }
        }
        .sheet(isPresented: $showQuickAddMyWordSheet) {
            MyWordEditorSheet(mode: .add, autofocusGermanOnAppear: true)
        }
        .sheet(isPresented: $showMyWordsStudy) {
            NavigationStack {
                StudyView(
                    dataService: dataService,
                    filterBySectionId: DataService.userMyWordsSectionId,
                    studyAllMode: true,
                    favoritesOnly: false,
                    categoryFilter: nil
                )
                .environmentObject(dataService)
            }
        }
        .alert(
            Localizable.string(Localizable.myWordsProLockedTitle),
            isPresented: $showQuickAddMyWordProAlert
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.myWordsProLockedMessage))
        }
        .onChange(of: deepLinkRouter.pendingRoute, initial: true) { _, route in
            guard let route else { return }
            switch route {
            case .tab(let section):
                selectedSection = section
                sectionBeforeSearch = section
                deepLinkRouter.clearPendingRoute()
            case .foregroundOnly:
                deepLinkRouter.clearPendingRoute()
            case .myWordsComposer:
                deepLinkRouter.clearPendingRoute()
                if isPremiumPreviewOverride == nil, !subscriptionManager.hasCompletedInitialSubscriptionSync {
                    pendingQuickAddAfterEntitlementSync = true
                    return
                }
                presentQuickAddGateOutcome()
            case .myWordsStudy:
                deepLinkRouter.clearPendingRoute()
                if isPremiumPreviewOverride == nil, !subscriptionManager.hasCompletedInitialSubscriptionSync {
                    pendingMyWordsStudyAfterEntitlementSync = true
                    return
                }
                presentMyWordsStudyGateOutcome()
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
    }

    // MARK: Deep Link Actions

    private func presentQuickAddGateOutcome() {
        if !isPremiumActionAuthorized {
            HapticManager.shared.heavyImpact()
            showQuickAddMyWordProAlert = true
            return
        }
        HapticManager.shared.lightImpact()
        DispatchQueue.main.async {
            DispatchQueue.main.async {
                showQuickAddMyWordSheet = true
            }
        }
    }

    private func presentMyWordsStudyGateOutcome() {
        if !isPremiumActionAuthorized {
            HapticManager.shared.heavyImpact()
            showQuickAddMyWordProAlert = true
            return
        }
        HapticManager.shared.lightImpact()
        selectedSection = .home
        sectionBeforeSearch = .home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showMyWordsStudy = true
        }
    }
}

// MARK: - Previews

private struct MainViewPreviewHost: View {
    let isPremiumPreviewOverride: Bool
    /// `""` keeps default Word of the Day preview selection.
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
            .environmentObject(AppDeepLinkRouter.shared)
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
