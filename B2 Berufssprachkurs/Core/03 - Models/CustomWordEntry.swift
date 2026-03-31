//
//  CustomWordEntry.swift
//  B2 Berufssprachkurs
//
//  User-authored vocabulary; stored in SwiftData with the same CloudKit configuration as WordProgress.
//

import Foundation
import SwiftData

@Model
final class CustomWordEntry {
    /// Non‑premium users may store up to this many entries; premium has no limit.
    enum FreeTier {
        static let maxWords = 5
    }

    var id: String = ""
    var german: String = ""
    var translation: String = ""
    var example: String?
    var explanation: String?
    var synonym: String?
    /// Display order within “My Words”; lower values appear first.
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    init(
        id: String = "myw_\(UUID().uuidString)",
        german: String,
        translation: String = "",
        example: String? = nil,
        explanation: String? = nil,
        synonym: String? = nil,
        sortIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.german = german
        self.translation = translation
        self.example = example
        self.explanation = explanation
        self.synonym = synonym
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }

    /// Ensures unique order keys (e.g. after schema add when every row had `sortIndex == 0`).
    @MainActor
    static func renumberSortOrderIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<CustomWordEntry>(
            sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)]
        )
        guard let all = try? context.fetch(descriptor), all.count > 1 else { return }
        let uniqueSortCount = Set(all.map(\.sortIndex)).count
        if uniqueSortCount == all.count { return }
        let sorted = all.sorted {
            if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
            return $0.createdAt < $1.createdAt
        }
        for (i, entry) in sorted.enumerated() {
            entry.sortIndex = i
        }
        try? context.save()
    }

    func asWord() -> Word {
        let ex = example?.trimmingCharacters(in: .whitespacesAndNewlines)
        let exp = explanation?.trimmingCharacters(in: .whitespacesAndNewlines)
        let syn = synonym?.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedSynonyms: [String]? = {
            guard let syn, !syn.isEmpty else { return nil }
            let parts = syn
                .split(whereSeparator: { $0 == "," || $0 == ";" })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return parts.isEmpty ? [syn] : parts
        }()
        return Word(
            id: id,
            german: german.trimmingCharacters(in: .whitespacesAndNewlines),
            translation: translation.trimmingCharacters(in: .whitespacesAndNewlines),
            synonyms: parsedSynonyms,
            explanation: (exp?.isEmpty == false) ? exp : nil,
            example: (ex?.isEmpty == false) ? ex : nil,
            quiz: nil
        )
    }

    @MainActor
    static func deleteAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<CustomWordEntry>()
        let all = try context.fetch(descriptor)
        for item in all {
            context.delete(item)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}
