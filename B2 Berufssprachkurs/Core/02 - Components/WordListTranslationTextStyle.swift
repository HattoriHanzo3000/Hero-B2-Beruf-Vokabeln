//
//  WordListTranslationTextStyle.swift
//  B2 Berufssprachkurs
//
//  Strong tint for user-written translations in word lists (per stack: general / Verben / Adjektive / Meine Wörter).
//

import SwiftUI

enum WordListTranslationTextStyle {
    static func color(for group: DataService.FavoriteGroupType, colorScheme: ColorScheme) -> Color {
        switch group {
        case .generalWords:
            if colorScheme == .dark {
                return Color(red: 0.42, green: 0.82, blue: 0.58)
            }
            return Color(red: 0.06, green: 0.38, blue: 0.22)
        case .verbs:
            if colorScheme == .dark {
                return Color(red: 0.52, green: 0.70, blue: 0.98)
            }
            return Color(red: 0.06, green: 0.18, blue: 0.48)
        case .adjectives:
            if colorScheme == .dark {
                return Color(red: 0.76, green: 0.60, blue: 0.94)
            }
            return Color(red: 0.30, green: 0.08, blue: 0.46)
        case .myWords:
            if colorScheme == .dark {
                return Color(red: 0.98, green: 0.48, blue: 0.52)
            }
            return Color(red: 0.50, green: 0.07, blue: 0.11)
        }
    }
}
