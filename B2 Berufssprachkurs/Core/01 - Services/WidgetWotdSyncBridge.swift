//
//  WidgetWotdSyncBridge.swift
//  B2 Berufssprachkurs
//
//  Mirrors Word of the Day settings and translations into the App Group for the widget extension.
//  Created: 03.07.26.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetWotdSyncBridge {
    private static var cachedWordsBySection: [String: [Word]]?
    private static var pendingSyncTask: Task<Void, Never>?

    /// Defers widget sync until after entitlement sync so premium sections are not clamped to free tier.
    static func scheduleSyncOnAppActivation(modelContext: ModelContext) {
        pendingSyncTask?.cancel()
        pendingSyncTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }

            await SubscriptionManager.shared.waitForInitialSubscriptionSync()
            guard !Task.isCancelled else { return }

            let descriptor = FetchDescriptor<WordProgress>()
            let progress = (try? modelContext.fetch(descriptor)) ?? []
            syncAll(
                wordProgress: progress,
                isPremiumActive: SubscriptionManager.shared.isPremiumActive
            )
        }
    }

    /// Coalesces rapid sync requests (e.g. multiple views appearing at launch).
    static func requestSync(
        wordProgress: [WordProgress],
        wordsBySection: [String: [Word]]? = nil,
        isPremiumActive: Bool,
        reloadWidget: Bool = true
    ) {
        pendingSyncTask?.cancel()
        pendingSyncTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            syncAll(
                wordProgress: wordProgress,
                wordsBySection: wordsBySection,
                isPremiumActive: isPremiumActive,
                reloadWidget: reloadWidget
            )
        }
    }

    static func syncAll(
        wordProgress: [WordProgress],
        wordsBySection: [String: [Word]]? = nil,
        isPremiumActive: Bool,
        reloadWidget: Bool = true
    ) {
        guard let defaults = UserDefaults(suiteName: QuickAddDeepLink.appGroupSuiteName) else { return }

        let sectionsCSV = sanitizedSectionsCSV(isPremiumActive: isPremiumActive)
        let periodicity = UserDefaults.standard.string(forKey: WordOfTheDayResolver.periodicityKey) ?? "24_hours"

        defaults.set(sectionsCSV, forKey: WordOfTheDayResolver.selectedSectionsKey)
        defaults.set(periodicity, forKey: WordOfTheDayResolver.periodicityKey)

        let vocabulary = resolvedWordsBySection(wordsBySection)
        syncTranslations(
            wordsBySection: vocabulary,
            selectedSectionsCSV: sectionsCSV,
            wordProgress: wordProgress
        )

        MainAppWidgetTimelineGenerator.generate(wordsBySection: vocabulary)

        if reloadWidget {
            reloadWidgetTimelines()
        }
    }

    static func updateTranslation(wordId: String, text: String) {
        WidgetTranslationStore.upsert(wordId: wordId, translation: text)
        MainAppWidgetTimelineGenerator.generate(wordsBySection: cachedWordsBySection)
        reloadWidgetTimelines()
    }

    // MARK: - Private

    private static func resolvedWordsBySection(_ wordsBySection: [String: [Word]]?) -> [String: [Word]] {
        if let wordsBySection {
            cachedWordsBySection = wordsBySection
            return wordsBySection
        }
        if let cachedWordsBySection {
            return cachedWordsBySection
        }
        let loaded = BundledVocabularyLoader.load().wordsBySection
        cachedWordsBySection = loaded
        return loaded
    }

    private static func sanitizedSectionsCSV(isPremiumActive: Bool) -> String {
        var csv = UserDefaults.standard.string(forKey: WordOfTheDayResolver.selectedSectionsKey) ?? ""
        if csv.isEmpty {
            csv = "1A"
        }
        guard !isPremiumActive else { return csv }
        return WordOfTheDaySelectionPolicy.sanitizedCSVForFreeTier(csv, applyDefaultIfEmpty: true)
    }

    /// CloudKit can produce duplicate `WordProgress` rows per `wordId`; keep the newest translation.
    private static func translationByWordId(from wordProgress: [WordProgress]) -> [String: String] {
        var bestRecordByWordId: [String: WordProgress] = [:]
        bestRecordByWordId.reserveCapacity(wordProgress.count)

        for record in wordProgress {
            if let existing = bestRecordByWordId[record.wordId] {
                if record.lastUpdated >= existing.lastUpdated {
                    bestRecordByWordId[record.wordId] = record
                }
            } else {
                bestRecordByWordId[record.wordId] = record
            }
        }

        return bestRecordByWordId.mapValues(\.translation)
    }

    private static func syncTranslations(
        wordsBySection: [String: [Word]],
        selectedSectionsCSV: String,
        wordProgress: [WordProgress]
    ) {
        let sectionIds = WordOfTheDaySelectionPolicy.selectionSetFromCSV(selectedSectionsCSV)
        let progressByWordId = translationByWordId(from: wordProgress)

        var translations: [String: String] = [:]
        for sectionId in sectionIds.sorted() {
            guard let words = wordsBySection[sectionId] else { continue }
            for word in words {
                let stored = progressByWordId[word.id]?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !stored.isEmpty {
                    translations[word.id] = stored
                } else {
                    let bundled = word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !bundled.isEmpty {
                        translations[word.id] = bundled
                    }
                }
            }
        }

        WidgetTranslationStore.save(translations)
    }

    private static func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: QuickAddDeepLink.wordOfTheDayWidgetKind)
    }
}
