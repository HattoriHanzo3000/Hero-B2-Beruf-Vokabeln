//
//  CockpitView.swift
//  B2 Berufssprachkurs
//
//  Dashboard screen for Word of the Day, progress, and Hero extras.
//  Created: 26.11.25.
//

import SwiftData
import SwiftUI

// MARK: - Screen

struct CockpitView: View {
    // MARK: Configuration

    private let isPremiumPreviewOverride: Bool?

    // MARK: State & Environment

    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = ""
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24_hours"
    @AppStorage("cockpitProgressWordScope") private var progressWordScopeRaw = DataService.ProgressWordScope.app.rawValue
    @Query(sort: \WordProgress.wordId) private var wordProgressRecords: [WordProgress]

    @State private var showMoreFromHeroSheet = false

    /// Pass `true` / `false` for canvas previews only; `nil` uses live subscription state.
    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
    }

    // MARK: View Layout

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            WordWallpaperBackground(dataService: dataService)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CockpitWordOfTheDaySection(
                        selectedSectionsCSV: $wordOfTheDaySelectedSections,
                        periodicity: $wordOfTheDayPeriodicity,
                        languageManager: languageManager,
                        dataService: dataService
                    )

                    CockpitProgressSection(
                        progressWordScopeRaw: $progressWordScopeRaw,
                        dataService: dataService,
                        reduceMotion: reduceMotion,
                        isPremiumPreviewOverride: isPremiumPreviewOverride
                    )

                    CockpitMoreFromHeroSection(showSheet: $showMoreFromHeroSheet)
                }
                .padding(.vertical)
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMoreFromHeroSheet) {
            AdvertisementView()
        }
        .onAppear {
            if wordOfTheDaySelectedSections.isEmpty {
                wordOfTheDaySelectedSections = "1A"
            }
            if !subscriptionManager.isPremiumActive {
                wordOfTheDaySelectedSections = WordOfTheDaySelectionPolicy.sanitizedCSVForFreeTier(
                    wordOfTheDaySelectedSections,
                    applyDefaultIfEmpty: true
                )
            }
            syncWordOfTheDayWidget()
        }
        .onChange(of: subscriptionManager.isPremiumActive) { _, _ in
            wordOfTheDaySelectedSections = WordOfTheDaySelectionPolicy.sanitizedCSVForFreeTier(
                wordOfTheDaySelectedSections,
                applyDefaultIfEmpty: false
            )
            syncWordOfTheDayWidget()
        }
        .onChange(of: wordOfTheDaySelectedSections) { _, _ in
            syncWordOfTheDayWidget()
        }
        .onChange(of: wordOfTheDayPeriodicity) { _, _ in
            syncWordOfTheDayWidget()
        }
    }

    private func syncWordOfTheDayWidget() {
        let isPremium = isPremiumPreviewOverride ?? subscriptionManager.isPremiumActive
        WidgetWotdSyncBridge.requestSync(
            wordProgress: wordProgressRecords,
            wordsBySection: dataService.wordsBySection,
            isPremiumActive: isPremium
        )
    }
}

// MARK: - Previews

private struct CockpitViewPreviewHost: View {
    let isPremiumPreviewOverride: Bool?

    init(isPremiumPreviewOverride: Bool?) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        LanguageManager.shared.currentLanguage = "Deutsch"
    }

    var body: some View {
        CockpitView(isPremiumPreviewOverride: isPremiumPreviewOverride)
            .environmentObject(DataService())
    }
}

private struct CockpitViewCanvasPreview: View {
    let isPremiumPreviewOverride: Bool?

    var body: some View {
        NavigationStack {
            CockpitViewPreviewHost(isPremiumPreviewOverride: isPremiumPreviewOverride)
        }
    }
}

#Preview("Cockpit — Free") {
    CockpitViewCanvasPreview(isPremiumPreviewOverride: false)
        .modelContainer(for: WordProgress.self, inMemory: true)
}

#Preview("Cockpit — Pro") {
    CockpitViewCanvasPreview(isPremiumPreviewOverride: true)
        .modelContainer(for: WordProgress.self, inMemory: true)
}
