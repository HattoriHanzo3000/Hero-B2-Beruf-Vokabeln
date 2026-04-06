//
//  StudyFlashCardContentResolver.swift
//  B2 Berufssprachkurs
//

import Foundation

enum StudyFlashCardContentResolver {
    static func frontText(for studyItem: StudyItem, contentType: StudyCardContentType) -> String {
        if studyItem.isVerbenSection {
            if contentType == .translation {
                if let translation = studyItem.translation, !trimmedIsEmpty(translation) {
                    return translation
                }
                return ""
            }
            if contentType == .explanation {
                if let explanation = studyItem.explanation, !trimmedIsEmpty(explanation) {
                    return explanation
                }
                return ""
            }
            if let quiz = studyItem.quiz, !trimmedIsEmpty(quiz) {
                return quiz
            }
            if let explanation = studyItem.explanation, !trimmedIsEmpty(explanation) {
                return explanation
            }
            return studyItem.example ?? ""
        }

        switch contentType {
        case .synonym:
            return studyItem.synonym ?? ""
        case .explanation:
            return studyItem.explanation ?? ""
        case .translation:
            return studyItem.translation ?? ""
        }
    }

    static func shouldShowPlaceholder(for studyItem: StudyItem, contentType: StudyCardContentType) -> Bool {
        if studyItem.isVerbenSection {
            if contentType == .translation {
                return trimmedIsEmpty(studyItem.translation ?? "")
            }
            if contentType == .explanation {
                return trimmedIsEmpty(studyItem.explanation ?? "")
            }
            return false
        }

        switch contentType {
        case .translation:
            return trimmedIsEmpty(studyItem.translation ?? "")
        case .explanation:
            return trimmedIsEmpty(studyItem.explanation ?? "")
        case .synonym:
            return trimmedIsEmpty(studyItem.synonym ?? "")
        }
    }

    static func emptyStateMessage(for contentType: StudyCardContentType) -> String {
        switch contentType {
        case .translation:
            return Localizable.string(Localizable.flashcardNoTranslationYet)
        case .explanation:
            return Localizable.string(Localizable.flashcardNoExplanationYet)
        case .synonym:
            return Localizable.string(Localizable.flashcardNoSynonymYet)
        }
    }

    static func resolvedContentTypeOnWordChange(
        for studyItem: StudyItem,
        current: StudyCardContentType
    ) -> StudyCardContentType {
        if studyItem.isVerbenSection {
            if current == .explanation {
                let explanation = studyItem.explanation ?? ""
                if trimmedIsEmpty(explanation),
                   let translation = studyItem.translation,
                   !trimmedIsEmpty(translation) {
                    return .translation
                }
            }
            return current
        }

        let isAvailable: Bool
        switch current {
        case .explanation:
            isAvailable = studyItem.explanation != nil
        case .translation:
            isAvailable = true
        case .synonym:
            isAvailable = studyItem.synonym != nil
        }

        if isAvailable {
            return current
        }
        if studyItem.explanation != nil {
            return .explanation
        }
        if studyItem.translation != nil {
            return .translation
        }
        if studyItem.synonym != nil {
            return .synonym
        }
        return .translation
    }

    private static func trimmedIsEmpty(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
