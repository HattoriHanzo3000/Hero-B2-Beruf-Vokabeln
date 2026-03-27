//
//  VerbsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct VerbsView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var navigateToStudy = false
    
    var hasAnySelection: Bool {
        dataService.hasAnyVerbenCompleted()
    }
    
    var body: some View {
        ZStack {
            Color("AppBlue").opacity(0.08)
                .ignoresSafeArea()
            
            ZStack(alignment: .bottom) {
                VerbsListView(dataService: dataService)
                
                VStack(spacing: 0) {
                    FloatingPracticeButton(
                        title: Localizable.string(Localizable.practice),
                        accent: Color("AppBlue"),
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
                studyAllMode: dataService.isVerbenCompleted(),
                categoryFilter: "VERBEN_"
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
        VerbsView()
            .environmentObject(DataService())
    }
}
