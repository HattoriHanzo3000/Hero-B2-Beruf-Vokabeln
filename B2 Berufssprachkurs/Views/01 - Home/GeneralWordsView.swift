//
//  GeneralWordsView.swift
//  B2 Berufssprachkurs
//
//  Home stack screen for general vocabulary and practice launch.
//  Created: 26.11.25.
//

import SwiftUI

// MARK: - Screen

struct GeneralWordsView: View {
    // MARK: State

    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var navigateToStudy = false

    // MARK: Derived Data

    private var hasAnySelection: Bool {
        dataService.hasAnyGeneralWordsPracticeSelection(isPremium: subscriptionManager.isPremiumActive)
    }

    // MARK: View Layout

    var body: some View {
        ZStack {
            LearningStackType.general.learningSurfaceBackground
                .ignoresSafeArea()

            GeneralWordsListView(dataService: dataService)
        }
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: nil,
                studyAllMode: dataService.areAllGeneralWordsCompletedForStudy(isPremium: subscriptionManager.isPremiumActive),
                categoryFilter: nil
            )
            .environmentObject(dataService)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FlashcardsButton.bottomTrailingInset(
                isEnabled: hasAnySelection,
                accent: Color("AppGreen")
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
        GeneralWordsView()
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
