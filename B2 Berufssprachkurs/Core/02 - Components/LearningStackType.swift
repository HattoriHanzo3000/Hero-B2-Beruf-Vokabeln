//
//  LearningStackType.swift
//  B2 Berufssprachkurs
//
//  Home hub navigation targets for vocabulary stacks.
//

import SwiftUI

enum LearningStackType: String, Identifiable, Hashable {
    case general
    case verbs
    case adjectives
    case myWords
    case favorites

    var id: String { rawValue }

    /// Order of stack cards on the home screen.
    static let homeStackOrder: [LearningStackType] = [
        .general, .verbs, .adjectives, .myWords, .favorites
    ]
}

extension LearningStackType {
    var localizedTitle: String {
        switch self {
        case .general: return Localizable.string(Localizable.generalWords)
        case .verbs: return Localizable.string(Localizable.verbsWithPrepositions)
        case .adjectives: return Localizable.string(Localizable.adjectivesWithPrepositions)
        case .myWords: return Localizable.string(Localizable.myWords)
        case .favorites: return Localizable.string(Localizable.favoritesWordsTitle)
        }
    }

    var accentColor: Color {
        switch self {
        case .general: return Color("AppGreen")
        case .verbs: return Color("AppBlue")
        case .adjectives: return Color("AppPurple")
        case .myWords: return Color("AppRed")
        case .favorites: return Color("AppYellow")
        }
    }

    var iconName: String {
        switch self {
        case .general: return "book.fill"
        case .verbs: return "figure.run"
        case .adjectives: return "paintpalette.fill"
        case .myWords: return "person.fill"
        case .favorites: return "star.fill"
        }
    }

    /// PRO badge + paywall for My Words when not premium.
    func isLockedOnHome(isPremium: Bool) -> Bool {
        self == .myWords && !isPremium
    }
}
