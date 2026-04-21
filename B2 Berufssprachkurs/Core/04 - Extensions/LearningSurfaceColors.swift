//
//  LearningSurfaceColors.swift
//  B2 Berufssprachkurs
//
//  Named asset colors for full-screen learning surfaces (light and dark appearances).
//

import SwiftUI

enum LearningSurfaceColors {

    // MARK: - Catalog

    static let generalWords = Color("LearningSurfaceGreen")
    static let verbs = Color("LearningSurfaceBlue")
    static let adjectives = Color("LearningSurfacePurple")
    static let favorites = Color("LearningSurfaceYellow")
    static let myWords = Color("LearningSurfaceRed")

    static func surface(forSectionId sectionId: String) -> Color {
        if sectionId == VocabularyCatalog.userMyWordsSectionId {
            return myWords
        }
        if sectionId.hasPrefix("VERBEN_") {
            return verbs
        }
        if sectionId.hasPrefix("ADJEKTIVE_") {
            return adjectives
        }
        return generalWords
    }

    // MARK: - Accent wash (previews / dynamic accents)

    static let washOpacityLight: Double = 0.08
    static let washOpacityDark: Double = 0.14

    static func adaptiveWash(accent: Color, colorScheme: ColorScheme) -> Color {
        let opacity = colorScheme == .dark ? washOpacityDark : washOpacityLight
        return accent.opacity(opacity)
    }
}

extension LearningStackType {
    var learningSurfaceBackground: Color {
        switch self {
        case .general: return LearningSurfaceColors.generalWords
        case .verbs: return LearningSurfaceColors.verbs
        case .adjectives: return LearningSurfaceColors.adjectives
        case .myWords: return LearningSurfaceColors.myWords
        case .favorites: return LearningSurfaceColors.favorites
        }
    }
}
