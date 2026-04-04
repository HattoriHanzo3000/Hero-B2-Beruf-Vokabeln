//
//  AdjectivesListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AdjectivesListView: View {
    @ObservedObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showProFeatureAlert = false

    private var adjectivesScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.adjectivesRootScrollRowId },
            set: { listUIState.setAdjectivesRootScrollRowId($0) }
        )
    }

    // Prepositions for Adjektive mit Präpositionen
    private let adjektivePrepositions: [Section] = [
        Section(id: "ADJEKTIVE_an", title: "an"),
        Section(id: "ADJEKTIVE_auf", title: "auf"),
        Section(id: "ADJEKTIVE_bei", title: "bei"),
        Section(id: "ADJEKTIVE_für", title: "für"),
        Section(id: "ADJEKTIVE_gegenüber", title: "gegenüber"),
        Section(id: "ADJEKTIVE_in", title: "in"),
        Section(id: "ADJEKTIVE_mit", title: "mit"),
        Section(id: "ADJEKTIVE_nach", title: "nach"),
        Section(id: "ADJEKTIVE_über", title: "über"),
        Section(id: "ADJEKTIVE_um", title: "um"),
        Section(id: "ADJEKTIVE_von", title: "von"),
        Section(id: "ADJEKTIVE_vor", title: "vor"),
        Section(id: "ADJEKTIVE_zu", title: "zu")
    ]

    private func isAdjektiveRowLocked(_ section: Section) -> Bool {
        !subscriptionManager.isPremiumActive
            && !DataService.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(section.id)
    }

    private func showLockedFeatureAlert() {
        HapticManager.shared.heavyImpact()
        showProFeatureAlert = true
    }
    
    var body: some View {
        FlatIndexedStackListView(
            dataService: dataService,
            accent: Color("AppPurple"),
            icon: "paintpalette.fill",
            title: Localizable.string(Localizable.adjectivesWithPrepositions),
            rows: adjektivePrepositions,
            stackHeaderId: "adjectives-stack-header",
            selectAllId: "adjectives-select-all",
            rowIdPrefix: "adjectives-row",
            scrollBinding: adjectivesScrollBinding,
            isAllSelected: dataService.areAllAdjektiveCompletedForStudy(isPremium: subscriptionManager.isPremiumActive),
            onToggleAll: {
                dataService.toggleAdjektiveCompletedForStudy(isPremium: subscriptionManager.isPremiumActive)
            },
            isRowLocked: isAdjektiveRowLocked,
            onLockedInteraction: showLockedFeatureAlert
        )
        .alert(
            Localizable.string(Localizable.proFeatureTitle),
            isPresented: $showProFeatureAlert
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.proFeatureOnlyMessage))
        }
    }
}

#Preview {
    NavigationStack {
        AdjectivesListView(dataService: DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}
