//
//  GeneralWordsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct GeneralWordsView: View {
    @EnvironmentObject private var dataService: DataService

    var body: some View {
        ZStack {
            Color("AppGreen").opacity(0.08)
                .ignoresSafeArea()

            GeneralWordsListView(dataService: dataService)
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
