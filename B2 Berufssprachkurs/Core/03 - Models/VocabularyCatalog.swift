//
//  VocabularyCatalog.swift
//  B2 Berufssprachkurs
//
//  Course identifiers, free-tier rules, and static section ID sets (bundled JSON).
//

import Foundation

enum VocabularyCatalog {
    /// Synthetic section for user-created entries (`CustomWordEntry`); not in bundle JSON.
    static let userMyWordsSectionId = "USER_MY_WORDS"

    /// Which vocabulary set drives the Cockpit progress ring and statistics.
    enum ProgressWordScope: String, CaseIterable, Identifiable, Hashable {
        case app
        case mine
        var id: String { rawValue }
    }

    /// General Words lections from `lections.json` (IDs 1…12). Without Pro, only lection `1` is selectable for practice.
    enum GeneralWordsFreeTier {
        static let unlockedLectionId = 1
        static func isLectionUnlockedWithoutPremium(_ lectionId: Int) -> Bool {
            lectionId == unlockedLectionId
        }
    }

    /// Verben mit Präpositionen: without Pro, only the **an** section is available for practice.
    enum VerbenFreeTier {
        static let unlockedSectionId = "VERBEN_an"
        static func isVerbenSectionUnlockedWithoutPremium(_ sectionId: String) -> Bool {
            sectionId == unlockedSectionId
        }
    }

    /// Adjektive mit Präpositionen: without Pro, only the **an** section is available for practice.
    enum AdjektiveFreeTier {
        static let unlockedSectionId = "ADJEKTIVE_an"
        static func isAdjektiveSectionUnlockedWithoutPremium(_ sectionId: String) -> Bool {
            sectionId == unlockedSectionId
        }
    }

    static let verbenPrepositionSlugs: [String] = [
        "an", "auf", "aus", "bei", "bis", "durch", "für", "gegen", "in", "mit",
        "nach", "über", "um", "unter", "von", "vor", "zu"
    ]

    static let adjektivePrepositionSlugs: [String] = [
        "an", "auf", "bei", "für", "gegenüber", "in", "mit", "nach", "über", "um", "von", "vor", "zu"
    ]

    /// Section IDs for VERBEN stacks (must match `sectionId` in bundled JSON).
    static var verbenSectionIds: Set<String> {
        Set(verbenPrepositionSlugs.map { "VERBEN_\($0)" })
    }

    /// Section IDs for ADJEKTIVE stacks (must match `sectionId` in bundled JSON).
    static var adjektiveSectionIds: Set<String> {
        Set(adjektivePrepositionSlugs.map { "ADJEKTIVE_\($0)" })
    }
}
