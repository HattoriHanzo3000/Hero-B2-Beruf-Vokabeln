//
//  StudySectionOriginFormatting.swift
//  B2 Berufssprachkurs
//
//  Section-origin labels for study flashcard hints (general section IDs; preposition + case for Verben/Adjektive).
//

import Foundation

enum StudySectionOriginFormatting {
    static func badgeCaption(sectionId: String, germanWord: String) -> String {
        if sectionId == VocabularyCatalog.userMyWordsSectionId {
            return Localizable.string(Localizable.searchBadgeMyWords)
        }
        if sectionId.hasPrefix("VERBEN_") || sectionId.hasPrefix("ADJEKTIVE_") {
            let preposition = SectionStackPresentation.prepositionSuffix(from: sectionId)
            if let caseSuffix = grammaticalCaseSuffix(from: germanWord) {
                return "\(preposition) \(caseSuffix)"
            }
            return preposition
        }
        return sectionId
    }

    private static func grammaticalCaseSuffix(from germanWord: String) -> String? {
        if germanWord.contains("(+ Dat.)") { return "(+ Dat.)" }
        if germanWord.contains("(+ Akk.)") { return "(+ Akk.)" }
        return nil
    }
}
