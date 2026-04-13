//
//  AdjectivesView.swift
//  B2 Berufssprachkurs
//
//  Home stack screen for adjective vocabulary and study entry.
//  Created: 26.11.25.
//

import SwiftUI

// MARK: - Screen

struct AdjectivesView: View {
    // MARK: State

    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var navigateToStudy = false
    
    // MARK: Derived Data

    var hasAnySelection: Bool {
        dataService.hasAnyAdjektivePracticeSelection(isPremium: subscriptionManager.isPremiumActive)
    }
    
    // MARK: View Layout

    var body: some View {
        ZStack {
            LearningStackType.adjectives.learningSurfaceBackground
                .ignoresSafeArea()

            AdjectivesListView(dataService: dataService)
        }
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: nil,
                studyAllMode: dataService.areAllAdjektiveCompletedForStudy(isPremium: subscriptionManager.isPremiumActive),
                categoryFilter: "ADJEKTIVE_"
            )
            .environmentObject(dataService)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FlashcardsButton.bottomTrailingInset(
                isEnabled: hasAnySelection,
                accent: Color("AppPurple")
            ) {
                navigateToStudy = true
            }
        }
        .hidesBottomBarWhenPushed(true)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdjectivesView()
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
