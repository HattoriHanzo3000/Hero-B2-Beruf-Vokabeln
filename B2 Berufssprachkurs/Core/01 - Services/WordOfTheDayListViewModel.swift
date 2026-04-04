//
//  WordOfTheDayListViewModel.swift
//  B2 Berufssprachkurs
//

import Combine
import SwiftUI

@MainActor
final class WordOfTheDayListViewModel: ObservableObject {
    @Published var selectedSectionIds: Set<String> = []
    @Published var showProFeatureAlert = false

    private let dataService: DataService
    private let subscriptionManager: SubscriptionManager

    init(dataService: DataService, subscriptionManager: SubscriptionManager) {
        self.dataService = dataService
        self.subscriptionManager = subscriptionManager
    }

    convenience init(dataService: DataService) {
        self.init(dataService: dataService, subscriptionManager: SubscriptionManager.shared)
    }

    var isPremiumActive: Bool {
        subscriptionManager.isPremiumActive
    }

    private var verbenIds: Set<String> {
        PrepositionStackCatalog.verbenSectionIds
    }

    private var adjektiveIds: Set<String> {
        PrepositionStackCatalog.adjektiveSectionIds
    }

    func loadFromCSV(_ csv: String) {
        selectedSectionIds = WordOfTheDaySelectionPolicy.selectionSetFromCSV(csv)
    }

    func csvForBinding() -> String {
        WordOfTheDaySelectionPolicy.csvFromSelectionSet(selectedSectionIds)
    }

    func sanitizeForFreeTier(applyDefaultIfEmpty: Bool) {
        selectedSectionIds = WordOfTheDaySelectionPolicy.sanitizedSelectionSetForFreeTier(
            selectedSectionIds,
            applyDefaultIfEmpty: applyDefaultIfEmpty
        )
    }

    func canSelectSection(_ sectionId: String) -> Bool {
        if isPremiumActive { return true }
        return WordOfTheDaySelectionPolicy.freeTierWotdSelectableSectionIDs.contains(sectionId)
    }

    func isLectionFullySelected(lection: Lection) -> Bool {
        let lectionSectionIds = Set(lection.sections.map(\.id))
        return lectionSectionIds.isSubset(of: selectedSectionIds)
    }

    func toggleLectionSelection(lection: Lection) {
        let lectionSectionIds = Set(lection.sections.map(\.id))
        let isFullySelected = lectionSectionIds.isSubset(of: selectedSectionIds)

        if isFullySelected {
            selectedSectionIds.subtract(lectionSectionIds)
        } else if isPremiumActive {
            selectedSectionIds.formUnion(lectionSectionIds)
        } else {
            let freeSectionIds = lectionSectionIds.filter {
                WordOfTheDaySelectionPolicy.freeTierAllowedSectionIDs.contains($0)
            }
            selectedSectionIds.formUnion(freeSectionIds)
        }
    }

    /// Single-section row (lection sub-row or VERBEN/ADJEKTIVE row).
    func toggleSectionRow(_ sectionId: String) {
        if selectedSectionIds.contains(sectionId) {
            selectedSectionIds.remove(sectionId)
        } else if canSelectSection(sectionId) {
            selectedSectionIds.insert(sectionId)
        } else {
            showProFeatureAlert = true
        }
    }

    func isVerbenFullySelected() -> Bool {
        if isPremiumActive {
            return verbenIds.isSubset(of: selectedSectionIds)
        }
        return selectedSectionIds.contains(DataService.VerbenFreeTier.unlockedSectionId)
    }

    func isAdjektiveFullySelected() -> Bool {
        if isPremiumActive {
            return adjektiveIds.isSubset(of: selectedSectionIds)
        }
        return selectedSectionIds.contains(DataService.AdjektiveFreeTier.unlockedSectionId)
    }

    func toggleAllVerbenSelection() {
        if isPremiumActive {
            if verbenIds.isSubset(of: selectedSectionIds) {
                selectedSectionIds.subtract(verbenIds)
            } else {
                selectedSectionIds.formUnion(verbenIds)
            }
        } else {
            let an = DataService.VerbenFreeTier.unlockedSectionId
            if selectedSectionIds.contains(an) {
                selectedSectionIds.remove(an)
            } else {
                selectedSectionIds.insert(an)
            }
        }
    }

    func toggleAllAdjektiveSelection() {
        if isPremiumActive {
            if adjektiveIds.isSubset(of: selectedSectionIds) {
                selectedSectionIds.subtract(adjektiveIds)
            } else {
                selectedSectionIds.formUnion(adjektiveIds)
            }
        } else {
            let an = DataService.AdjektiveFreeTier.unlockedSectionId
            if selectedSectionIds.contains(an) {
                selectedSectionIds.remove(an)
            } else {
                selectedSectionIds.insert(an)
            }
        }
    }

    private var allSectionIds: Set<String> {
        let regular = Set(dataService.lections.flatMap { $0.sections.map(\.id) })
        return regular.union(verbenIds).union(adjektiveIds)
    }

    func isAllSelected() -> Bool {
        if isPremiumActive {
            return allSectionIds.isSubset(of: selectedSectionIds)
        }
        return WordOfTheDaySelectionPolicy.freeTierWotdSelectableSectionIDs.isSubset(of: selectedSectionIds)
    }

    func toggleSelectAllToolbar() {
        if isAllSelected() {
            selectedSectionIds.removeAll()
        } else if isPremiumActive {
            let allRegularSectionIds = Set(dataService.lections.flatMap { $0.sections.map(\.id) })
            selectedSectionIds = allRegularSectionIds.union(verbenIds).union(adjektiveIds)
        } else {
            selectedSectionIds = WordOfTheDaySelectionPolicy.freeTierWotdSelectableSectionIDs
        }
    }
}
