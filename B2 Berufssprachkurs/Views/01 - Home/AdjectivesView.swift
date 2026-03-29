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
            
            ZStack(alignment: .bottom) {
                AdjectivesListView(dataService: dataService)
                
                VStack(spacing: 0) {
                    FloatingPracticeButton(
                        title: Localizable.string(Localizable.practice),
                        accent: Color("AppPurple"),
                        isEnabled: hasAnySelection
                    ) {
                        HapticManager.shared.mediumImpact()
                        navigateToStudy = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
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
