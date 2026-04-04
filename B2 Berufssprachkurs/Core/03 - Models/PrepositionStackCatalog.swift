//
//  PrepositionStackCatalog.swift
//  B2 Berufssprachkurs
//
//  Single source of truth for Verben / Adjektive mit Präpositionen section IDs and titles.
//

import Foundation

enum PrepositionStackCatalog {
    /// Verben mit Präpositionen — matches `wordsBySection` keys with prefix `VERBEN_`.
    static let verbenWithPrepositions: [Section] = [
        Section(id: "VERBEN_an", title: "an"),
        Section(id: "VERBEN_auf", title: "auf"),
        Section(id: "VERBEN_aus", title: "aus"),
        Section(id: "VERBEN_bei", title: "bei"),
        Section(id: "VERBEN_bis", title: "bis"),
        Section(id: "VERBEN_durch", title: "durch"),
        Section(id: "VERBEN_für", title: "für"),
        Section(id: "VERBEN_gegen", title: "gegen"),
        Section(id: "VERBEN_in", title: "in"),
        Section(id: "VERBEN_mit", title: "mit"),
        Section(id: "VERBEN_nach", title: "nach"),
        Section(id: "VERBEN_über", title: "über"),
        Section(id: "VERBEN_um", title: "um"),
        Section(id: "VERBEN_unter", title: "unter"),
        Section(id: "VERBEN_von", title: "von"),
        Section(id: "VERBEN_vor", title: "vor"),
        Section(id: "VERBEN_zu", title: "zu")
    ]

    /// Adjektive mit Präpositionen — matches `wordsBySection` keys with prefix `ADJEKTIVE_`.
    static let adjektiveWithPrepositions: [Section] = [
        Section(id: "ADJEKTIVE_an", title: "an"),
        Section(id: "ADJEKTIVE_auf", title: "auf"),
        Section(id: "ADJEKTIVE_bei", title: "bei"),
        Section(id: "ADJEKTIVE_für", title: "für"),
        Section(id: "ADJEKTIVE_gegenüber", title: "gegenüber"),
        Section(id: "ADJEKTIVE_in", title: "in"),
        Section(id: "ADJEKTIVE_mit", title: "mit"),
        Section(id: "ADJEKTIVE_nach", title: "nach"),
        Section(id: "ADJEKTIVE_über", title: "über"),
        Section(id: "ADJEKTIVE_um", title: "um"),
        Section(id: "ADJEKTIVE_von", title: "von"),
        Section(id: "ADJEKTIVE_vor", title: "vor"),
        Section(id: "ADJEKTIVE_zu", title: "zu")
    ]

    static var verbenSectionIds: Set<String> {
        Set(verbenWithPrepositions.map(\.id))
    }

    static var adjektiveSectionIds: Set<String> {
        Set(adjektiveWithPrepositions.map(\.id))
    }
}
