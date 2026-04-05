//
//  LearningSurfaceColors.swift
//  B2 Berufssprachkurs
//
//  Full-screen learning surfaces (word lists, study). Each stack uses a named color in Assets with
//  **light and dark** appearances so backgrounds stay on-brand in both modes.
//

import SwiftUI

/// Central access to learning-area background colors (tinted washes, not raw accent fills).
enum LearningSurfaceColors {

    // MARK: - Catalog surfaces (preferred)

    /// General words / course vocabulary (green family). Asset: `LearningSurfaceGreen`.
    static let generalWords = Color("LearningSurfaceGreen")

    /// Verbs with prepositions (blue family). Asset: `LearningSurfaceBlue`.
    static let verbs = Color("LearningSurfaceBlue")

    /// Adjectives with prepositions (purple family). Asset: `LearningSurfacePurple`.
    static let adjectives = Color("LearningSurfacePurple")

    /// Favorites (yellow family). Asset: `LearningSurfaceYellow`.
    static let favorites = Color("LearningSurfaceYellow")

    /// My Words (red family). Asset: `LearningSurfaceRed`.
    static let myWords = Color("LearningSurfaceRed")

    /// Full-screen list surface for a vocabulary section (matches ``StudyStackKind`` / ``SectionStackPresentation``).
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

    // MARK: - Opacity-based wash (fallback)

    /// Light mode wash strength when deriving from a dynamic accent color.
    static let washOpacityLight: Double = 0.08

    /// Dark mode wash strength (slightly stronger so tints read on dark system backgrounds).
    static let washOpacityDark: Double = 0.14

    /// Use when the surface must be built from a SwiftUI `Color` (e.g. previews) instead of catalog stacks.
    static func adaptiveWash(accent: Color, colorScheme: ColorScheme) -> Color {
        let opacity = colorScheme == .dark ? washOpacityDark : washOpacityLight
        return accent.opacity(opacity)
    }
}

extension LearningStackType {
    /// Full-screen list background for this hub stack (same catalog as ``StudyStackKind`` surfaces).
    var learningSurfaceBackground: Color {
        switch self {
        case .general:
            return LearningSurfaceColors.generalWords
        case .verbs:
            return LearningSurfaceColors.verbs
        case .adjectives:
            return LearningSurfaceColors.adjectives
        case .myWords:
            return LearningSurfaceColors.myWords
        case .favorites:
            return LearningSurfaceColors.favorites
        }
    }
}
