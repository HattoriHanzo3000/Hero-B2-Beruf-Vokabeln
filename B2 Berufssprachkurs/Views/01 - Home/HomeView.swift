//
//  HomeView.swift
//  B2 Berufssprachkurs
//
//  Main home screen presenting learning stacks and navigation entry points.
//  Created: 26.11.25.
//

import SwiftData
import SwiftUI

// MARK: - Home stack row press style
/// Adds a subtle pressed-state response for stack cards.
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
    // MARK: State & Environment

    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    private let isPremiumPreviewOverride: Bool?
    @State private var activeStack: LearningStackType?
    @State private var showPaywall = false
    @State private var showMyWordsProAlert = false

    // MARK: Initialization

    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
    }

    // MARK: Derived Data

    private var isPremiumForVisuals: Bool {
        isPremiumPreviewOverride ?? subscriptionManager.isPremiumVisualState
    }

    private var isPremiumActionAuthorized: Bool {
        if let isPremiumPreviewOverride {
            return isPremiumPreviewOverride
        }
        return subscriptionManager.isPremiumAuthorizationGranted
    }

    // MARK: View Layout

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

    // MARK: User Actions

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

// MARK: - Previews

/// Keeps preview language aligned with the app's German option.
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

/// Hosts previews with required environment objects and model container.
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
