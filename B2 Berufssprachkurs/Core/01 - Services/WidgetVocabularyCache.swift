//
//  WidgetVocabularyCache.swift
//  B2 Berufssprachkurs
//
//  In-memory cache of bundled vocabulary for main-app widget timeline generation.
//  Created: 03.07.26.
//

import Foundation

enum WidgetVocabularyCache {
    private static var cachedWordsBySection: [String: [Word]]?

    static var wordsBySection: [String: [Word]] {
        if let cachedWordsBySection {
            return cachedWordsBySection
        }
        let loaded = BundledVocabularyLoader.load().wordsBySection
        cachedWordsBySection = loaded
        return loaded
    }

    static func setCachedWordsBySection(_ wordsBySection: [String: [Word]]) {
        cachedWordsBySection = wordsBySection
    }
}
