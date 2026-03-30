//
//  AdjectivesView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AdjectivesView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var navigateToStudy = false
    
    var hasAnySelection: Bool {
        dataService.hasAnyAdjektivePracticeSelection(isPremium: subscriptionManager.isPremiumActive)
    }
    
    var body: some View {
        ZStack {
            Color("AppPurple").opacity(0.08)
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                FloatingPracticeButton(
                    title: Localizable.string(Localizable.practiceWithCards),
                    accent: Color("AppPurple"),
                    isEnabled: hasAnySelection,
                    compactForToolbar: true
                ) {
                    HapticManager.shared.mediumImpact()
                    navigateToStudy = true
                }
            }
        }
        .hidesBottomBarWhenPushed(true)
    }
}

#Preview {
    NavigationStack {
        AdjectivesView()
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
