//
//  StudySelectionState.swift
//  B2 Berufssprachkurs
//
//  Singleton SwiftData row: section/lection completion and per-section checked word IDs (JSON).
//  CloudKit-backed when sync is enabled (same container as WordProgress).
//

import Foundation
import SwiftData

enum StudySelectionStateKeys {
    static let singletonKey = "default"
}

@Model
final class StudySelectionState {
    /// One row per store; value must match ``StudySelectionStateKeys.singletonKey``.
    var singletonKey: String = StudySelectionStateKeys.singletonKey
    var completedLectionIds: [Int] = []
    var completedSectionIds: [String] = []
    /// JSON object: `{ "sectionId": ["wordId", …], … }`
    var checkedWordsJSON: String = "{}"
    var lastUpdated: Date = Date()

    init(
        singletonKey: String = StudySelectionStateKeys.singletonKey,
        completedLectionIds: [Int] = [],
        completedSectionIds: [String] = [],
        checkedWordsJSON: String = "{}",
        lastUpdated: Date = Date()
    ) {
        self.singletonKey = singletonKey
        self.completedLectionIds = completedLectionIds
        self.completedSectionIds = completedSectionIds
        self.checkedWordsJSON = checkedWordsJSON
        self.lastUpdated = lastUpdated
    }
}

// MARK: - IO

extension StudySelectionState {
    static func checkedWords(from json: String) -> [String: Set<String>] {
        guard let data = json.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        var result: [String: Set<String>] = [:]
        for (section, ids) in raw {
            result[section] = Set(ids)
        }
        return result
    }

    static func json(from checkedWords: [String: Set<String>]) -> String {
        let encodable = checkedWords.mapValues { Array($0).sorted() }
        guard let data = try? JSONEncoder().encode(encodable),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    @MainActor
    static func fetchOrInsertSingleton(in context: ModelContext) -> StudySelectionState {
        let key = StudySelectionStateKeys.singletonKey
        var descriptor = FetchDescriptor<StudySelectionState>(
            predicate: #Predicate<StudySelectionState> { $0.singletonKey == key }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = StudySelectionState()
        context.insert(created)
        return created
    }

    @MainActor
    static func deleteAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<StudySelectionState>()
        let all = try context.fetch(descriptor)
        for item in all {
            context.delete(item)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}
