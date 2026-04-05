//
//  StudyCardContentSupport.swift
//  B2 Berufssprachkurs
//

import Foundation

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

    /// User can always choose Übersetzung; empty text shows the flashcard placeholder (course words + Meine Wörter).
    static func isContentTypeAvailable(_ type: StudyCardContentType, for item: StudyItem) -> Bool {
        if item.isVerbenSection {
            switch type {
            case .translation:
                return true
            case .explanation:
                return hasNonWhitespace(item.explanation)
            case .synonym:
                return false
            }
        }
        switch type {
        case .synonym:
            if item.sectionId == DataService.userMyWordsSectionId {
                return true
            }
            return item.synonym != nil
        case .explanation:
            if item.sectionId == DataService.userMyWordsSectionId {
                return true
            }
            return item.explanation != nil
        case .translation:
            return true
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

    /// Priority: Erklärung → Übersetzung → Synonym (course sections).
    /// My Words: first mode with non-empty text, else Übersetzung — so German-only entries default to the translation placeholder.
    static func firstAvailableContentType(for item: StudyItem) -> StudyCardContentType {
        if item.sectionId == DataService.userMyWordsSectionId, !item.isVerbenSection {
            if hasNonWhitespace(item.explanation) {
                return .explanation
            }
            if hasNonWhitespace(item.synonym) {
                return .synonym
            }
            return .translation
        }
        for type in [StudyCardContentType.explanation, .translation, .synonym] {
            if hasNonEmptyStudyContent(type, for: item) {
                return type
            }
        }
        return .translation
    }

    /// Chip row order: **My Words** always shows all three modes (user may fill content later). **Course / Verben** shows only available types but always includes Übersetzung so the user can open the keyboard.
    static func displayTypes(for item: StudyItem) -> [StudyCardContentType] {
        let availableTypes = StudyCardContentType.displayOrder.filter { type in
            isContentTypeAvailable(type, for: item)
        }

        if item.sectionId == DataService.userMyWordsSectionId, !item.isVerbenSection {
            return StudyCardContentType.displayOrder
        }
        var types = availableTypes
        if !types.contains(.translation) {
            types.append(.translation)
        }
        return StudyCardContentType.displayOrder.filter { types.contains($0) }
    }

    private static func hasNonWhitespace(_ text: String?) -> Bool {
        guard let text else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
