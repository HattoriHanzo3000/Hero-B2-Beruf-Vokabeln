//
//  VerbsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct VerbsListView: View {
    @ObservedObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    private var verbsScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.verbsRootScrollRowId },
            set: { listUIState.setVerbsRootScrollRowId($0) }
        )
    }

    // Prepositions for Verben mit Präpositionen
    private let verbenPrepositions: [Section] = [
        Section(id: "VERBEN_an", title: "an"),
        Section(id: "VERBEN_auf", title: "auf"),
        Section(id: "VERBEN_aus", title: "aus"),
        Section(id: "VERBEN_bei", title: "bei"),
        Section(id: "VERBEN_bis", title: "bis"),
        Section(id: "VERBEN_durch", title: "durch"),
        Section(id: "VERBEN_für", title: "für"),
        Section(id: "VERBEN_gegen", title: "gegen"),
        Section(id: "VERBEN_in", title: "in"),
        Section(id: "VERBEN_mit", title: "mit"),
        Section(id: "VERBEN_nach", title: "nach"),
        Section(id: "VERBEN_über", title: "über"),
        Section(id: "VERBEN_um", title: "um"),
        Section(id: "VERBEN_unter", title: "unter"),
        Section(id: "VERBEN_von", title: "von"),
        Section(id: "VERBEN_vor", title: "vor"),
        Section(id: "VERBEN_zu", title: "zu")
    ]

    private func isVerbenRowLocked(_ section: Section) -> Bool {
        !subscriptionManager.isPremiumActive
            && !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(section.id)
    }

    private func requestPaywall() {
        HapticManager.shared.heavyImpact()
        showPaywall = true
    }
    
    var body: some View {
        FlatIndexedStackListView(
            dataService: dataService,
            accent: Color("AppBlue"),
            icon: "figure.run",
            title: Localizable.string(Localizable.verbsWithPrepositions),
            rows: verbenPrepositions,
            stackHeaderId: "verbs-stack-header",
            selectAllId: "verbs-select-all",
            rowIdPrefix: "verbs-row",
            scrollBinding: verbsScrollBinding,
            isAllSelected: subscriptionManager.isPremiumActive && dataService.isVerbenCompleted(),
            onToggleAll: {
                if subscriptionManager.isPremiumActive {
                    dataService.toggleVerbenCompleted()
                } else {
                    requestPaywall()
                }
            },
            isRowLocked: isVerbenRowLocked,
            onLockedInteraction: requestPaywall
        )
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    NavigationStack {
        VerbsListView(dataService: DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}

