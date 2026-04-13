//
//  StudyCardContentSupport.swift
//  B2 Berufssprachkurs
//
//  Determines available flashcard content types for study items.
//  Created: 04.04.26.
//

import Foundation

// MARK: - StudyCardContentSupport

enum StudyCardContentSupport {
    static func typeButtonTitle(for type: StudyCardContentType) -> String {
        switch type {
        case .explanation:
            return Localizable.string(Localizable.explanation)
        case .translation:
            return Localizable.string(Localizable.translation)
        case .synonym:
            return Localizable.string(Localizable.synonym)
        }
    }

    /// Chip availability policy:
    /// - My Words: all three chips are available.
    /// - Course/Favorites cards not from My Words: only Übersetzung + Erklärung.
    static func isContentTypeAvailable(_ type: StudyCardContentType, for item: StudyItem) -> Bool {
        let isMyWordsCard = item.sectionId == DataService.userMyWordsSectionId && !item.isVerbenSection
        if isMyWordsCard { return true }
        switch type {
        case .translation, .explanation:
            return true
        case .synonym:
            return false
        }
    }

    static func hasNonEmptyStudyContent(_ type: StudyCardContentType, for item: StudyItem) -> Bool {
        if item.isVerbenSection {
            switch type {
            case .translation:
                return hasNonWhitespace(item.translation)
            case .explanation:
                return hasNonWhitespace(item.explanation)
            case .synonym:
                return false
            }
        }
        switch type {
        case .synonym:
            return hasNonWhitespace(item.synonym)
        case .explanation:
            return hasNonWhitespace(item.explanation)
        case .translation:
            return hasNonWhitespace(item.translation)
        }
    }

    /// Session default is always Übersetzung.
    static func firstAvailableContentType(for item: StudyItem) -> StudyCardContentType {
        return .translation
    }

    /// Chip row policy:
    /// - My Words card: Übersetzung, Erklärung, Synonym.
    /// - Other cards (General/Verben/Adjektive and matching Favorites cards): Übersetzung, Erklärung.
    static func displayTypes(for item: StudyItem) -> [StudyCardContentType] {
        if item.sectionId == DataService.userMyWordsSectionId, !item.isVerbenSection {
            return StudyCardContentType.displayOrder
        }
        return [.translation, .explanation]
    }

    private static func hasNonWhitespace(_ text: String?) -> Bool {
        guard let text else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
