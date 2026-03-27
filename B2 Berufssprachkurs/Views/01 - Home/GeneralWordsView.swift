//
//  GeneralWordsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct GeneralWordsView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var navigateToStudy = false
    
    var hasAnySelection: Bool {
        dataService.hasAnyLectionCompleted()
    }
    
    var body: some View {
        ZStack {
            Color("AppGreen").opacity(0.08)
                .ignoresSafeArea()
            
            ZStack(alignment: .bottom) {
                GeneralWordsListView(dataService: dataService)
                
                VStack(spacing: 0) {
                    FloatingPracticeButton(
                        title: Localizable.string(Localizable.practice),
                        accent: Color("AppGreen"),
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
                studyAllMode: dataService.areAllLectionsCompleted(),
                categoryFilter: nil
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
        GeneralWordsView()
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
