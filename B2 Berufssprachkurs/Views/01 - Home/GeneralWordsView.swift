//
//  GeneralWordsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct GeneralWordsView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var navigateToStudy = false
    
    var hasAnySelection: Bool {
        dataService.hasAnyGeneralWordsPracticeSelection(isPremium: subscriptionManager.isPremiumActive)
    }
    
    var body: some View {
        ZStack {
            Color("AppGreen").opacity(0.08)
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                FloatingPracticeButton(
                    title: Localizable.string(Localizable.practiceWithCards),
                    accent: Color("AppGreen"),
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
        GeneralWordsView()
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
