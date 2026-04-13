//
//  LearningListsUIState.swift
//  B2 Berufssprachkurs
//
//  Stores shared UI state for learning list navigation and scrolling.
//  Created: 27.03.26.
//

import Combine
import SwiftUI

// MARK: - LearningListsUIState

@MainActor
final class LearningListsUIState: ObservableObject {
    static let shared = LearningListsUIState()

    /// Expanded lection headers on the general words stack root.
    @Published var generalWordsExpandedLectionIds: Set<Int> = []

    /// `scrollPosition` id for `GeneralWordsListView` (`gw-lection-*`, `gw-section-*`, etc.).
    @Published var generalWordsScrollRowId: String?

    /// Last scroll anchor word id per `WordsListView`, keyed by `sectionId`.
    @Published private var wordsListScrollWordIdBySection: [String: String] = [:]

    @Published var verbsRootScrollRowId: String?

    @Published var adjectivesRootScrollRowId: String?

    private init() {}

    func wordsListScrollWordId(for sectionId: String) -> String? {
        wordsListScrollWordIdBySection[sectionId]
    }

    /// Avoid publishing when the scroll id is unchanged — `scrollPosition` writes often and would
    /// otherwise re-run parent views (and every row) in a tight loop.
    func setWordsListScrollWordId(_ id: String?, for sectionId: String) {
        if let id {
            if wordsListScrollWordIdBySection[sectionId] == id { return }
        } else {
            if wordsListScrollWordIdBySection[sectionId] == nil { return }
        }
        var map = wordsListScrollWordIdBySection
        if let id {
            map[sectionId] = id
        } else {
            map.removeValue(forKey: sectionId)
        }
        wordsListScrollWordIdBySection = map
    }

    func setGeneralWordsScrollRowId(_ id: String?) {
        guard generalWordsScrollRowId != id else { return }
        generalWordsScrollRowId = id
    }

    func setVerbsRootScrollRowId(_ id: String?) {
        guard verbsRootScrollRowId != id else { return }
        verbsRootScrollRowId = id
    }

    func setAdjectivesRootScrollRowId(_ id: String?) {
        guard adjectivesRootScrollRowId != id else { return }
        adjectivesRootScrollRowId = id
    }

    func toggleGeneralWordsLectionExpanded(_ lectionId: Int) {
        var next = generalWordsExpandedLectionIds
        if next.contains(lectionId) {
            next.remove(lectionId)
        } else {
            next.insert(lectionId)
        }
        generalWordsExpandedLectionIds = next
    }
}
