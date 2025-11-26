//
//  HomeView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var dataService = DataService()
    @State private var selectedButtonType: ToolbarButtonType = .translation
    @State private var navigateToStudy = false
    @State private var navigateToSettings = false
    
    var body: some View {
        ZStack {
            Color("AppGreenLight")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HeaderView(dataService: dataService)
                
                // Üben button group
                UbenButtonGroup(
                    selectedButtonType: $selectedButtonType,
                    onButtonTap: { buttonType in
                        navigateToStudy = true
                    }
                )
                
                // Lections list
                LectionsListView(dataService: dataService)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 12)
                
                // Banner Ad at the bottom
                BannerAd()
                    .padding(.bottom, 8)
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
        .navigationDestination(isPresented: $navigateToSettings) {
            SettingsView()
                .environmentObject(dataService)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}

