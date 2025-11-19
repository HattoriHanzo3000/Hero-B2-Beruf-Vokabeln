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
                        // Handle explanation tap
                    },
                    onSynonymTap: {
                        HapticManager.shared.selection()
                        // Handle synonym tap
                    },
                    onTranslationTap: {
                        HapticManager.shared.selection()
                        // Handle translation tap
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
                
                // ÜBEN button at the bottom
                UbenButton(
                    action: {
                        HapticManager.shared.mediumImpact()
                        // Handle ÜBEN tap
                    },
                    accentColor: selectedButtonType.color,
                    buttonText: selectedButtonType.buttonText
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .environmentObject(dataService)
    }
}

#Preview {
    NavigationView {
        HomeView()
    }
}

