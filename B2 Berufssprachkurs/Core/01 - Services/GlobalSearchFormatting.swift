//
//  GlobalSearchFormatting.swift
//  B2 Berufssprachkurs
//
//  Formats localized context labels for global search result badges.
//  Created: 05.04.26.
//

import Foundation

// MARK: - Formatting

enum GlobalSearchFormatting {
    static func contextLabel(for sectionId: String) -> String {
        if sectionId == VocabularyCatalog.userMyWordsSectionId {
            return Localizable.string(Localizable.searchBadgeMyWords)
        }
        if sectionId.hasPrefix("VERBEN_") {
            return Localizable.string(Localizable.searchBadgeVerbs)
        }
        if sectionId.hasPrefix("ADJEKTIVE_") {
            return Localizable.string(Localizable.searchBadgeAdjectives)
        }
        return sectionId
    }
}
