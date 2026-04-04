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
    @State private var showProFeatureAlert = false

    private var verbsScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.verbsRootScrollRowId },
            set: { listUIState.setVerbsRootScrollRowId($0) }
        )
    }

    private func isVerbenRowLocked(_ section: Section) -> Bool {
        !subscriptionManager.isPremiumActive
            && !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(section.id)
    }

    private func showLockedFeatureAlert() {
        HapticManager.shared.heavyImpact()
        showProFeatureAlert = true
    }
    
    var body: some View {
        FlatIndexedStackListView(
            dataService: dataService,
            accent: Color("AppBlue"),
            icon: "figure.run",
            title: Localizable.string(Localizable.verbsWithPrepositions),
            rows: PrepositionStackCatalog.verbenWithPrepositions,
            stackHeaderId: "verbs-stack-header",
            selectAllId: "verbs-select-all",
            rowIdPrefix: "verbs-row",
            scrollBinding: verbsScrollBinding,
            isAllSelected: dataService.areAllVerbenCompletedForStudy(isPremium: subscriptionManager.isPremiumActive),
            onToggleAll: {
                dataService.toggleVerbenCompletedForStudy(isPremium: subscriptionManager.isPremiumActive)
            },
            isRowLocked: isVerbenRowLocked,
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
        VerbsListView(dataService: DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}

