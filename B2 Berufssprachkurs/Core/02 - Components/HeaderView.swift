//
//  HeaderView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftData
import SwiftUI

struct HeaderView: View {
    @ObservedObject var dataService: DataService
    @Query(sort: \WordProgress.wordId) var wordProgressRecords: [WordProgress]
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    let isPremiumPreviewOverride: Bool?
    /// When `true`, only greeting / mascot / word-of-the-day are shown (no pinned gradient shell). Use on Home with a full-screen background gradient.
    let embedInScrollContent: Bool
    /// When set (e.g. from `HomeView`), the free-tier “start free trial” label opens the paywall.
    let showPaywall: Binding<Bool>?
    @State var wordOfTheDay: Word? = nil
    @AppStorage("wordOfTheDayPeriodicity") var wordOfTheDayPeriodicity = "24_hours"
    @AppStorage("wordOfTheDaySelectedSections") var wordOfTheDaySelectedSections = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(
        dataService: DataService,
        isPremiumPreviewOverride: Bool? = nil,
        embedInScrollContent: Bool = false,
        showPaywall: Binding<Bool>? = nil
    ) {
        self.dataService = dataService
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        self.embedInScrollContent = embedInScrollContent
        self.showPaywall = showPaywall
    }

    var body: some View {
        Group {
            if embedInScrollContent {
                mainHeaderContent
            } else {
                ZStack(alignment: .top) {
                    pinnedHeaderGradientBackground
                    mainHeaderContent
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            updateWordOfTheDay()
        }
        .onChange(of: dataService.wordsBySection) { _, _ in
            updateWordOfTheDay()
        }
        .onChange(of: wordOfTheDayPeriodicity) { _, _ in
            updateWordOfTheDay()
        }
        .onChange(of: wordOfTheDaySelectedSections) { _, _ in
            updateWordOfTheDay()
        }
        .dynamicTypeSize(headerDynamicTypeRange)
    }

    /// Header copy uses a fixed typographic scale (not Dynamic Type).
    var headerDynamicTypeRange: ClosedRange<DynamicTypeSize> {
        .large ... .large
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    HeaderView(dataService: DataService())
        .background(LearningSurfaceColors.generalWords)
        .modelContainer(container)
}
