//
//  LearningListsUIState.swift
//  B2 Berufssprachkurs
//
//  Preserves list expansion and scroll anchors across push/pop (e.g. general words → section list).
//

import Combine
import SwiftUI

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

    func setWordsListScrollWordId(_ id: String?, for sectionId: String) {
        var map = wordsListScrollWordIdBySection
        if let id {
            map[sectionId] = id
        } else {
            map.removeValue(forKey: sectionId)
        }
        wordsListScrollWordIdBySection = map
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
