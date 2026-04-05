//
//  GlobalSearchFormatting.swift
//  B2 Berufssprachkurs
//
//  Localized short labels for global search result rows.
//

import Foundation

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
