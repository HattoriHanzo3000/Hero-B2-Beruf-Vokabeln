//
//  GeneralWordsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct GeneralWordsListView: View {
    @ObservedObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showProFeatureAlert = false

    private var generalWordsScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.generalWordsScrollRowId },
            set: { listUIState.setGeneralWordsScrollRowId($0) }
        )
    }

    private func isLectionLocked(_ lectionId: Int) -> Bool {
        !subscriptionManager.isPremiumActive
            && !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lectionId)
    }

    private func showLockedFeatureAlert() {
        HapticManager.shared.heavyImpact()
        showProFeatureAlert = true
    }

    var body: some View {
        StackRootListShell {
            List {
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    ScrollableStackRootHeader(
                        accent: Color("AppGreen"),
                        icon: "book.fill",
                        title: Localizable.string(Localizable.generalWords)
                    )
                    .id("gw-stack-header")
                }

                SwiftUI.Section {
                    EmptyView()
                } header: {
                    StackListSelectAllHeader(
                        isSelected: dataService.areAllGeneralWordsCompletedForStudy(isPremium: subscriptionManager.isPremiumActive),
                        fontDesign: .default,
                        action: {
                            dataService.toggleAllGeneralWordsForStudy(isPremium: subscriptionManager.isPremiumActive)
                        }
                    )
                    .id("gw-select-all")
                }

                ForEach(Array(dataService.lections.prefix(GeneralWordsListCatalog.visibleLectionCount))) { lection in
                    SwiftUI.Section {
                        if listUIState.generalWordsExpandedLectionIds.contains(lection.id) {
                            ForEach(lection.sections) { section in
                                SectionRowView(
                                    section: section,
                                    lection: lection,
                                    dataService: dataService,
                                    isLocked: isLectionLocked(lection.id),
                                    onPaywall: showLockedFeatureAlert
                                )
                                .listRowBackground(Color.clear)
                                .id("gw-section-\(section.id)")
                            }
                        }
                    } header: {
                        LectionHeaderView(
                            lection: lection,
                            isExpanded: listUIState.generalWordsExpandedLectionIds.contains(lection.id),
                            onToggle: {
                                listUIState.toggleGeneralWordsLectionExpanded(lection.id)
                            },
                            dataService: dataService,
                            isLocked: isLectionLocked(lection.id),
                            onPaywall: showLockedFeatureAlert
                        )
                        .id("gw-lection-\(lection.id)")
                    }
                }
            }
            .stackRootListChrome(
                scrollPosition: generalWordsScrollBinding,
                bottomMargin: FlashcardsButton.fabSize + 24
            )
        }
        .alert(
            Localizable.string(Localizable.proFeatureTitle),
            isPresented: $showProFeatureAlert
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.proFeatureOnlyMessage))
        }
        .onAppear {
            dataService.sanitizeCompletedSelectionsForCurrentTier(isPremium: subscriptionManager.isPremiumActive)
        }
        .onChange(of: subscriptionManager.isPremiumActive) { _, isPremium in
            dataService.sanitizeCompletedSelectionsForCurrentTier(isPremium: isPremium)
        }
    }
}

#Preview {
    GeneralWordsListView(dataService: DataService())
        .environmentObject(LearningListsUIState.shared)
        .background(LearningSurfaceColors.generalWords)
}
