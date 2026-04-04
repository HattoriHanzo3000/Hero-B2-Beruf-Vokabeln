//
//  SectionStackPresentation.swift
//  B2 Berufssprachkurs
//
//  Shared stack chrome (color, icon, title) for section-scoped word lists.
//

import SwiftUI

enum SectionStackPresentation {
    struct Info {
        let color: Color
        let iconSystemName: String
        let title: String
    }

    static func wordListStack(for sectionId: String) -> Info {
        if sectionId == DataService.userMyWordsSectionId {
            return Info(
                color: Color("AppRed"),
                iconSystemName: "person.fill",
                title: Localizable.string(Localizable.myWords)
            )
        }
        if sectionId.hasPrefix("VERBEN_") {
            return Info(
                color: Color("AppBlue"),
                iconSystemName: "figure.run",
                title: Localizable.string(Localizable.verbsWithPrepositions)
            )
        }
        if sectionId.hasPrefix("ADJEKTIVE_") {
            return Info(
                color: Color("AppPurple"),
                iconSystemName: "paintpalette.fill",
                title: Localizable.string(Localizable.adjectivesWithPrepositions)
            )
        }
        return Info(
            color: Color("AppGreen"),
            iconSystemName: "book.fill",
            title: Localizable.string(Localizable.generalWords)
        )
    }

    /// Preposition token from ids such as `VERBEN_an` / `ADJEKTIVE_an`.
    static func prepositionSuffix(from sectionId: String) -> String {
        guard sectionId.hasPrefix("VERBEN_") || sectionId.hasPrefix("ADJEKTIVE_") else { return "" }
        let parts = sectionId.split(separator: "_")
        return parts.count > 1 ? String(parts[1]) : ""
    }
}
