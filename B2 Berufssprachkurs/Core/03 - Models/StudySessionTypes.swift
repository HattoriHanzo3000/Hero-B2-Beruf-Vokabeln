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

    /// Full-screen wash; uses catalog colors with light/dark appearances (see ``LearningSurfaceColors``).
    var backgroundColor: Color {
        switch self {
        case .generalWords:
            return LearningSurfaceColors.generalWords
        case .verbs:
            return LearningSurfaceColors.verbs
        case .adjectives:
            return LearningSurfaceColors.adjectives
        case .favorites:
            return LearningSurfaceColors.favorites
        case .myWords:
            return LearningSurfaceColors.myWords
        }
    }

    static func resolve(
        filterBySectionId: String?,
        categoryFilter: String?,
        studyItems: [StudyItem],
        favoritesOnly: Bool = false
    ) -> StudyStackKind {
        if filterBySectionId == DataService.userMyWordsSectionId {
            return .myWords
        }
        if studyItems.isEmpty {
            return .generalWords
        }

        if favoritesOnly {
            return .favorites
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
