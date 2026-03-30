//
//  VerbsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct VerbsView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var navigateToStudy = false
    
    var hasAnySelection: Bool {
        dataService.hasAnyVerbenPracticeSelection(isPremium: subscriptionManager.isPremiumActive)
    }
    
    var body: some View {
        ZStack {
            Color("AppBlue").opacity(0.08)
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

#Preview {
    NavigationStack {
        VerbsView()
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
