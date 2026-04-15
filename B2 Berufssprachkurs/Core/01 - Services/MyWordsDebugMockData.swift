//
//  MyWordsDebugMockData.swift
//  B2 Berufssprachkurs
//
//  Fixed “My Words” sample rows for DEBUG tooling (About → Debug).
//  Created: 15.04.26.
//

import Foundation
import SwiftData

// MARK: - Mock Rows

enum MyWordsDebugMockData {
    /// Matches `@AppStorage` in ``AboutDebugSheet``.
    static let appStorageKey = "isMockDataEnabled"

    struct Row: Sendable {
        let german: String
        let translation: String
        let example: String
        let explanation: String
        let synonym: String
    }

    /// Canonical mock vocabulary used for screenshots and QA.
    static let rows: [Row] = [
        Row(
            german: "der Papierkram",
            translation: "the paperwork",
            example: "Ich muss am Wochenende den ganzen Papierkram für die Steuer erledigen.",
            explanation: "Lästige administrative Aufgaben.",
            synonym: "die Bürokratie"
        ),
        Row(
            german: "der Feierabend",
            translation: "quitting time",
            example: "Endlich Feierabend! Zeit für ein kühles Getränk.",
            explanation: "Das Ende des Arbeitstages.",
            synonym: "der Dienstschluss"
        ),
        Row(
            german: "der Ohrwurm",
            translation: "catchy tune",
            example: "Dieses Lied ist ein echter Ohrwurm, ich singe es ständig.",
            explanation: "Ein Lied, das man nicht mehr aus dem Kopf bekommt.",
            synonym: "der Hit"
        ),
        Row(
            german: "das Sauwetter",
            translation: "awful weather",
            example: "Bei diesem Sauwetter bleibe ich lieber gemütlich auf dem Sofa.",
            explanation: "Sehr schlechtes und ungemütliches Wetter.",
            synonym: "das Mistwetter"
        ),
        Row(
            german: "der Besserwisser",
            translation: "know-it-all",
            example: "Mein Nachbar ist ein Besserwisser und korrigiert mich immer.",
            explanation: "Jemand, der glaubt, alles besser zu wissen.",
            synonym: "der Wichtigtuer"
        ),
    ]

    private static var mockGermanPhrases: [String] {
        rows.map(\.german)
    }

    // MARK: - Apply

    /// Inserts any missing mock rows (idempotent).
    static func insertMissingMocks(in context: ModelContext) throws {
        var nextSort = nextSortIndex(in: context)
        for row in rows {
            let g = row.german
            var descriptor = FetchDescriptor<CustomWordEntry>(
                predicate: #Predicate<CustomWordEntry> { $0.german == g }
            )
            descriptor.fetchLimit = 1
            if try context.fetch(descriptor).first != nil { continue }

            let entry = CustomWordEntry(
                german: row.german,
                translation: row.translation,
                example: row.example,
                explanation: row.explanation,
                synonym: row.synonym,
                sortIndex: nextSort
            )
            nextSort += 1
            context.insert(entry)
        }
        if context.hasChanges {
            try context.save()
        }
    }

    /// Removes every `CustomWordEntry` whose German text matches the mock set (favorites + progress cleaned).
    static func removeAllMocks(dataService: DataService, modelContext: ModelContext) throws {
        var toDelete: [CustomWordEntry] = []
        for g in mockGermanPhrases {
            let descriptor = FetchDescriptor<CustomWordEntry>(
                predicate: #Predicate<CustomWordEntry> { $0.german == g }
            )
            toDelete.append(contentsOf: try modelContext.fetch(descriptor))
        }
        guard !toDelete.isEmpty else { return }
        CustomWordEntryDeletion.deleteAll(toDelete, dataService: dataService, modelContext: modelContext)
    }

    // MARK: - Helpers

    private static func nextSortIndex(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CustomWordEntry>()
        guard let all = try? context.fetch(descriptor) else { return 0 }
        return (all.map(\.sortIndex).max() ?? -1) + 1
    }
}
