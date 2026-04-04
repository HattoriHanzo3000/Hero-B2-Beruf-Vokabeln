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
                if let explanation = item.explanation {
                    return !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                return false
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
                guard let translation = item.translation else { return false }
                return !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .explanation:
                guard let explanation = item.explanation else { return false }
                return !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .synonym:
                return false
            }
        }
        switch type {
        case .synonym:
            guard let s = item.synonym else { return false }
            return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .explanation:
            guard let e = item.explanation else { return false }
            return !e.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .translation:
            guard let t = item.translation else { return false }
            return !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Priority: Erklärung → Übersetzung → Synonym (course sections).
    /// My Words: first mode with non-empty text, else Übersetzung — so German-only entries default to the translation placeholder.
    static func firstAvailableContentType(for item: StudyItem) -> StudyCardContentType {
        if item.sectionId == DataService.userMyWordsSectionId, !item.isVerbenSection {
            if let explanation = item.explanation,
               !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .explanation
            }
            if let syn = item.synonym,
               !syn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
}
