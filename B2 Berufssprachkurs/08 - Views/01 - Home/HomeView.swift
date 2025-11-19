//
//  HomeView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var dataService = DataService()
    @State private var selectedButtonType: ToolbarButtonType = .explanation
    @State private var navigateToStudy = false
    
    var body: some View {
        ZStack {
            Color("AppGreenLight")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HeaderView(dataService: dataService)
                
                // Action buttons header
                ActionButtonsHeaderView(
                    onExplanationTap: {
                        HapticManager.shared.selection()
                        selectedButtonType = .explanation
                    },
                    onSynonymTap: {
                        HapticManager.shared.selection()
                        selectedButtonType = .synonym
                    },
                    onTranslationTap: {
                        HapticManager.shared.selection()
                        selectedButtonType = .translation
                    },
                    onCheckmarkTap: {
                        HapticManager.shared.mediumImpact()
                        dataService.toggleAllLections()
                    },
                    onSettingsTap: {
                        HapticManager.shared.lightImpact()
                        // Handle settings tap
                    },
                    isCheckmarkSelected: dataService.areAllLectionsCompleted(),
                    selectedButtonType: $selectedButtonType
                )
                
                // Lections list
                LectionsListView(dataService: dataService)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 12)

                
                Spacer()
                
                UbenButton(
                    action: {
                        HapticManager.shared.mediumImpact()
                        navigateToStudy = true
                    },
                    accentColor: selectedButtonType.color,
                    buttonText: selectedButtonType.buttonText
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .environmentObject(dataService)
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                mode: StudyMode(from: selectedButtonType),
                dataService: dataService,
                filterBySectionId: nil, // Home view: process all sections
                studyAllMode: dataService.areAllLectionsCompleted() // Study all if all lections are checked
            )
            .environmentObject(dataService)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}

