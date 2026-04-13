//
//  WordOfTheDayListView.swift
//  B2 Berufssprachkurs
//
//  Selection screen defining sections used for Word of the Day.
//  Created: 23.11.25.
//

import SwiftUI

// MARK: - Screen

struct WordOfTheDayListView: View {
    // MARK: Inputs & State

    @Binding var selectedSections: String
    @ObservedObject var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @StateObject private var viewModel: WordOfTheDayListViewModel

    // MARK: Initialization

    init(selectedSections: Binding<String>, dataService: DataService) {
        self._selectedSections = selectedSections
        self.dataService = dataService
        _viewModel = StateObject(wrappedValue: WordOfTheDayListViewModel(dataService: dataService))
    }

    // MARK: Derived Data

    private var isPremiumForVisuals: Bool {
        subscriptionManager.isPremiumVisualState
    }

    // MARK: View Layout

    var body: some View {
        NavigationStack {
            ZStack {
                LearningSurfaceColors.generalWords
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(dataService.lections) { lection in
                            WotdSelectionCard {
                                HStack(spacing: 12) {
                                    WotdLectionIndexBadge.circle(
                                        numberText: "\(lection.id)",
                                        fillColor: Color("AppGreen")
                                    )

                                    Text(lection.title)
                                        .font(.title2.weight(.semibold))
                                        .foregroundColor(.primary)

                                    if !isPremiumForVisuals,
                                       lection.id != DataService.GeneralWordsFreeTier.unlockedLectionId {
                                        ProShieldBadge(
                                            label: "PRO",
                                            color: Color.primary.opacity(0.72),
                                            showShimmer: false,
                                            style: .compact
                                        )
                                    }

                                    Spacer()

                                    BouncingSelectionCheckmark(
                                        isSelected: viewModel.isLectionFullySelected(lection: lection),
                                        isHeaderRow: true
                                    )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if subscriptionManager.isPremiumActive
                                        || lection.id == DataService.GeneralWordsFreeTier.unlockedLectionId {
                                        HapticManager.shared.lightImpact()
                                        withAnimation(WotdListSelection.spring) {
                                            viewModel.toggleLectionSelection(lection: lection)
                                        }
                                    } else {
                                        HapticManager.shared.heavyImpact()
                                        viewModel.showProFeatureAlert = true
                                    }
                                }
                            } content: {
                                VStack(spacing: 8) {
                                    ForEach(lection.sections) { section in
                                        WotdSourceSectionRow(
                                            leadingGlyph: WordOfTheDaySelectionPolicy.sectionLetter(fromSectionId: section.id),
                                            title: section.title,
                                            isSelected: viewModel.selectedSectionIds.contains(section.id),
                                            showProBadge: !viewModel.canSelectSection(section.id),
                                            rowEnabled: viewModel.canSelectSection(section.id),
                                            showDividerBelow: section.id != lection.sections.last?.id
                                        ) {
                                            let id = section.id
                                            if viewModel.selectedSectionIds.contains(id) {
                                                HapticManager.shared.lightImpact()
                                                withAnimation(WotdListSelection.spring) {
                                                    viewModel.toggleSectionRow(id)
                                                }
                                            } else if viewModel.canSelectSection(id) {
                                                HapticManager.shared.lightImpact()
                                                withAnimation(WotdListSelection.spring) {
                                                    viewModel.toggleSectionRow(id)
                                                }
                                            } else {
                                                HapticManager.shared.heavyImpact()
                                                viewModel.showProFeatureAlert = true
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        verbenCard
                        adjektiveCard
                    }
                    .padding(.vertical, 10)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(Localizable.string(Localizable.wordOfTheDay))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        withAnimation(WotdListSelection.spring) {
                            viewModel.toggleSelectAllToolbar()
                        }
                    } label: {
                        BouncingSelectionCheckmark(
                            isSelected: viewModel.isAllSelected(),
                            outlineIsCheckmarkCircle: true,
                            toolbarStyled: true
                        )
                    }
                    .accessibilityLabel(Text(Localizable.string(Localizable.selectAll)))
                }
            }
        }
        .onAppear {
            viewModel.loadFromCSV(selectedSections)
            if !subscriptionManager.isPremiumActive {
                viewModel.sanitizeForFreeTier(applyDefaultIfEmpty: true)
                selectedSections = viewModel.csvForBinding()
            }
        }
        .onChange(of: subscriptionManager.isPremiumActive) { _, _ in
            viewModel.sanitizeForFreeTier(applyDefaultIfEmpty: false)
            selectedSections = viewModel.csvForBinding()
        }
        .onDisappear {
            selectedSections = viewModel.csvForBinding()
        }
        .alert(
            Localizable.string(Localizable.proFeatureTitle),
            isPresented: $viewModel.showProFeatureAlert
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.proFeatureOnlyMessage))
        }
    }

    // MARK: Components

    private var verbenCard: some View {
        let rows = PrepositionStackCatalog.verbenWithPrepositions
        return WotdSelectionCard {
            HStack(spacing: 12) {
                WotdLectionIndexBadge.circle(
                    numberText: "13",
                    fillColor: Color("AppBlue")
                )

                Text(Localizable.string(Localizable.verbsWithPrepositions))
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                BouncingSelectionCheckmark(
                    isSelected: viewModel.isVerbenFullySelected(),
                    isHeaderRow: true
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.shared.lightImpact()
                withAnimation(WotdListSelection.spring) {
                    viewModel.toggleAllVerbenSelection()
                }
            }
        } content: {
            VStack(spacing: 8) {
                ForEach(rows) { item in
                    WotdSourceSectionRow(
                        leadingGlyph: nil,
                        title: item.title,
                        isSelected: viewModel.selectedSectionIds.contains(item.id),
                        showProBadge: !viewModel.canSelectSection(item.id),
                        rowEnabled: viewModel.canSelectSection(item.id),
                        showDividerBelow: item.id != rows.last?.id
                    ) {
                        togglePrepositionRow(item.id)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var adjektiveCard: some View {
        let rows = PrepositionStackCatalog.adjektiveWithPrepositions
        return WotdSelectionCard {
            HStack(spacing: 12) {
                WotdLectionIndexBadge.circle(
                    numberText: "14",
                    fillColor: Color("AppPurple")
                )

                Text(Localizable.string(Localizable.adjectivesWithPrepositions))
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                BouncingSelectionCheckmark(
                    isSelected: viewModel.isAdjektiveFullySelected(),
                    isHeaderRow: true
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.shared.lightImpact()
                withAnimation(WotdListSelection.spring) {
                    viewModel.toggleAllAdjektiveSelection()
                }
            }
        } content: {
            VStack(spacing: 8) {
                ForEach(rows) { item in
                    WotdSourceSectionRow(
                        leadingGlyph: nil,
                        title: item.title,
                        isSelected: viewModel.selectedSectionIds.contains(item.id),
                        showProBadge: !viewModel.canSelectSection(item.id),
                        rowEnabled: viewModel.canSelectSection(item.id),
                        showDividerBelow: item.id != rows.last?.id
                    ) {
                        togglePrepositionRow(item.id)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: User Actions

    private func togglePrepositionRow(_ sectionId: String) {
        if viewModel.selectedSectionIds.contains(sectionId) {
            HapticManager.shared.lightImpact()
            withAnimation(WotdListSelection.spring) {
                viewModel.toggleSectionRow(sectionId)
            }
        } else if viewModel.canSelectSection(sectionId) {
            HapticManager.shared.lightImpact()
            withAnimation(WotdListSelection.spring) {
                viewModel.toggleSectionRow(sectionId)
            }
        } else {
            HapticManager.shared.heavyImpact()
            viewModel.showProFeatureAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    WordOfTheDayListView(
        selectedSections: .constant(""),
        dataService: DataService()
    )
}
