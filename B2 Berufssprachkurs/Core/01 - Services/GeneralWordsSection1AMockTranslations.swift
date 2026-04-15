//
//  GeneralWordsSection1AMockTranslations.swift
//  B2 Berufssprachkurs
//
//  DEBUG: fills or clears user English translations for Lektion 1 / section 1A (screenshots).
//  Created: 15.04.26.
//

import Foundation
import SwiftData

// MARK: - Mock map

enum GeneralWordsSection1AMockTranslations {
    /// Lection 1 — “Berufliche Einstiege” (`chapter_1_A.json`).
    static let sectionId = "1A"

    /// Matches `@AppStorage` in ``AboutDebugSheet``.
    static let appStorageKey = "isGeneralWords1AMockTranslationsEnabled"

    /// Word IDs from bundled content → English gloss for the translation field (`WordProgress`).
    /// First three spell out masculine/female and “to adapt” for screenshot clarity.
    static let translationByWordId: [String: String] = [
        "1A-1": "the graduate (masculine)",
        "1A-2": "the graduate (feminine)",
        "1A-3": "to adapt (to + acc.)",
        "1A-4": "careers adviser (male)",
        "1A-5": "careers adviser (female)",
        "1A-6": "division of labour",
        "1A-7": "world of work",
        "1A-8": "because of, due to (+ dat.)",
        "1A-9": "meaning, significance",
        "1A-10": "to assert oneself, hold one’s own",
        "1A-11": "career path",
        "1A-12": "digitalization",
        "1A-13": "to prepare oneself for, get ready for (+ acc.)",
        "1A-14": "required, necessary",
        "1A-15": "to acquire, gain (skills / knowledge)",
        "1A-16": "employed person / wage earner (male)",
        "1A-17": "employed person / wage earner (female)",
        "1A-18": "freelancer (male)",
        "1A-19": "freelancer (female)",
        "1A-20": "globalization",
        "1A-21": "challenge",
        "1A-22": "intercultural competence",
        "1A-23": "climate change",
        "1A-24": "competence, skill",
        "1A-25": "to modernize",
        "1A-26": "reorientation, fresh start (career)",
        "1A-27": "to settle (somewhere), set up practice",
        "1A-28": "ecological, environmentally friendly",
        "1A-29": "break-time chat, coffee-break conversation",
        "1A-30": "technology",
        "1A-31": "interruption",
        "1A-32": "company, enterprise",
        "1A-33": "to become obsolete",
        "1A-34": "to trust in (+ acc.)",
    ]

    static var managedWordIds: [String] {
        translationByWordId.keys.sorted()
    }

    // MARK: - Apply

    /// Writes mock English translations for every managed `1A` word id.
    @MainActor
    static func applyEnabled(_ enabled: Bool, modelContext: ModelContext) {
        if enabled {
            for (wordId, text) in translationByWordId {
                WordProgress.upsertTranslation(wordId: wordId, text: text, in: modelContext)
            }
        } else {
            for wordId in managedWordIds {
                WordProgress.upsertTranslation(wordId: wordId, text: "", in: modelContext)
            }
        }
    }

    /// Re-applies translations when the toggle is already on (e.g. after relaunch).
    @MainActor
    static func syncIfNeeded(isEnabled: Bool, modelContext: ModelContext) {
        guard isEnabled else { return }
        applyEnabled(true, modelContext: modelContext)
    }
}
