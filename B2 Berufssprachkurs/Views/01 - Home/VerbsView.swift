//
//  VerbsView.swift
//  B2 Berufssprachkurs
//
//  Home stack screen for verb vocabulary and study entry.
//  Created: 26.11.25.
//

import SwiftUI

// MARK: - Screen

struct VerbsView: View {
    // MARK: State

    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var navigateToStudy = false
    
    // MARK: Derived Data

    var hasAnySelection: Bool {
        dataService.hasAnyVerbenPracticeSelection(isPremium: subscriptionManager.isPremiumActive)
    }
    
    // MARK: View Layout

    var body: some View {
        ZStack {
            LearningStackType.verbs.learningSurfaceBackground
                .ignoresSafeArea()

            VerbsListView(dataService: dataService)
        }
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: nil,
                studyAllMode: dataService.areAllVerbenCompletedForStudy(isPremium: subscriptionManager.isPremiumActive),
                categoryFilter: "VERBEN_"
            )
            .environmentObject(dataService)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FlashcardsButton.bottomTrailingInset(
                isEnabled: hasAnySelection,
                accent: Color("AppBlue")
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
        VerbsView()
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
