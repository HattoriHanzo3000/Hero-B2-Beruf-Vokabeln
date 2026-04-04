//
//  StudySessionTypes.swift
//  B2 Berufssprachkurs
//

import SwiftUI

enum StudyButtonFeedback {
    case correct
    case wrong
}

/// Which study face is active on the card (synonym, explanation, translation).
enum StudyCardContentType: String, CaseIterable, Hashable {
    case explanation
    case translation
    case synonym

    /// Study mode order: Übersetzung, Erklärung, Synonym
    static var displayOrder: [StudyCardContentType] {
        [.translation, .explanation, .synonym]
    }
}

/// Visual stack theme for the study screen background.
enum StudyStackKind {
    case generalWords
    case verbs
    case adjectives
    case favorites
    case myWords

    var accentColor: Color {
        switch self {
        case .generalWords:
            return Color("AppGreen")
        case .verbs:
            return Color("AppBlue")
        case .adjectives:
            return Color("AppPurple")
        case .favorites:
            return Color("AppYellow")
        case .myWords:
            return Color("AppRed")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .generalWords:
            return Color("AppGreenLight")
        case .verbs:
            return Color("AppBlueLight")
        case .adjectives:
            return Color("AppPurple").opacity(0.08)
        case .favorites:
            return Color("AppYellow").opacity(0.08)
        case .myWords:
            return Color("AppRed").opacity(0.08)
        }
    }

    static func resolve(
        filterBySectionId: String?,
        categoryFilter: String?,
        studyItems: [StudyItem]
    ) -> StudyStackKind {
        if filterBySectionId == DataService.userMyWordsSectionId {
            return .myWords
        }
        if studyItems.isEmpty {
            return .generalWords
        }

        if let sectionId = filterBySectionId {
            if sectionId.hasPrefix("VERBEN_") {
                return .verbs
            }
            if sectionId.hasPrefix("ADJEKTIVE_") {
                return .adjectives
            }
        }

        if let categoryFilter {
            if categoryFilter == "VERBEN_" {
                return .verbs
            }
            if categoryFilter == "ADJEKTIVE_" {
                return .adjectives
            }
        }

        let allVerben = studyItems.allSatisfy(\.isVerbenSection)
        if allVerben {
            return .verbs
        }

        let allAdjektive = studyItems.allSatisfy { $0.sectionId.hasPrefix("ADJEKTIVE_") }
        if allAdjektive {
            return .adjectives
        }

        return .generalWords
    }
}
