//
//  HomeView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftData
import SwiftUI

// MARK: - Home stack row press style
/// Subtle scale and opacity on press, similar to system list rows and tappable cards.
private struct HomeStackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Home
struct HomeView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    private let isPremiumPreviewOverride: Bool?
    @State private var activeStack: LearningStackType?
    @State private var showPaywall = false
    @State private var showMyWordsProAlert = false

    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
    }

    private var isPremiumForVisuals: Bool {
        isPremiumPreviewOverride ?? subscriptionManager.isPremiumVisualState
    }

    private var isPremiumActionAuthorized: Bool {
        if let isPremiumPreviewOverride {
            return isPremiumPreviewOverride
        }
        return subscriptionManager.isPremiumAuthorizationGranted
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            WordWallpaperBackground(dataService: dataService)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HeaderView(
                    dataService: dataService,
                    isPremiumPreviewOverride: isPremiumPreviewOverride,
                    embedInScrollContent: false,
                    showPaywall: $showPaywall
                )
                .id("header_\(languageManager.currentLanguage)")

                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            Spacer(minLength: 0)
                            VStack(spacing: 28) {
                                ForEach(LearningStackType.homeStackOrder, id: \.self) { stack in
                                    Button {
                                        handleStackTap(stack)
                                    } label: {
                                        LearningStackCard(
                                            title: stack.localizedTitle,
                                            accent: stack.accentColor,
                                            icon: stack.iconName,
                                            isLocked: stack.isLockedOnHome(isPremium: isPremiumForVisuals)
                                        )
                                        .frame(maxWidth: .infinity, minHeight: 76)
                                    }
                                    .buttonStyle(HomeStackButtonStyle())
                                    .id("\(stack.id)_\(languageManager.currentLanguage)")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            Spacer(minLength: 0)
                        }
                        .padding(.bottom, 32)
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(
            Localizable.string(Localizable.myWordsProLockedTitle),
            isPresented: $showMyWordsProAlert
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.myWordsProLockedMessage))
        }
        .navigationDestination(item: $activeStack) { stack in
            switch stack {
            case .general:
                GeneralWordsView()
                    .environmentObject(dataService)
                    .environmentObject(LearningListsUIState.shared)
            case .verbs:
                VerbsView()
                    .environmentObject(dataService)
                    .environmentObject(LearningListsUIState.shared)
            case .adjectives:
                AdjectivesView()
                    .environmentObject(dataService)
                    .environmentObject(LearningListsUIState.shared)
            case .favorites:
                FavoritesView()
                    .environmentObject(dataService)
                    .environmentObject(LearningListsUIState.shared)
            case .myWords:
                MyWordsView()
                    .environmentObject(dataService)
                    .environmentObject(LearningListsUIState.shared)
            }
        }
    }

    private func handleStackTap(_ stack: LearningStackType) {
        if stack == .myWords && !isPremiumActionAuthorized {
            HapticManager.shared.heavyImpact()
            showMyWordsProAlert = true
            return
        }
        HapticManager.shared.lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activeStack = stack
        }
    }
}

/// Ensures canvas previews use German strings (matches `LanguageManager` “Deutsch” option).
private struct HomeViewPreviewHost: View {
    let isPremiumPreviewOverride: Bool?

    init(isPremiumPreviewOverride: Bool?) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        LanguageManager.shared.currentLanguage = "Deutsch"
    }

    var body: some View {
        HomeView(isPremiumPreviewOverride: isPremiumPreviewOverride)
    }
}

/// Previews must attach `environmentObject` and `modelContainer` to `NavigationStack`, not only to `HomeView`.
/// Otherwise `navigationDestination` pushes (e.g. `GeneralWordsView` → lists using `LearningListsUIState`, `HeaderView` / `WordsListView` `@Query`) run without required environment and crash.
private struct HomeViewCanvasPreview: View {
    let isPremiumPreviewOverride: Bool?

    private static let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: WordProgress.self,
            CustomWordEntry.self,
            StudySelectionState.self,
            FavoriteWord.self,
            SpacedRepetitionRecord.self,
            configurations: config
        )
    }()

    var body: some View {
        NavigationStack {
            HomeViewPreviewHost(isPremiumPreviewOverride: isPremiumPreviewOverride)
        }
        .environmentObject(DataService())
        .environmentObject(LearningListsUIState.shared)
        .modelContainer(Self.previewContainer)
    }
}

#Preview("Home — Free") {
    HomeViewCanvasPreview(isPremiumPreviewOverride: false)
}

#Preview("Home — Pro") {
    HomeViewCanvasPreview(isPremiumPreviewOverride: true)
}
