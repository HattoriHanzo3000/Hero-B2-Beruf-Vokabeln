//
//  DataService.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class DataService: ObservableObject {
    @Published var lections: [Lection] = []
    @Published var wordsBySection: [String: [Word]] = [:]
    @Published var completedSections: Set<String> = []
    @Published var completedLections: Set<Int> = []
    @Published var checkedWords: [String: Set<String>] = [:] // sectionId: Set<wordId>
    @Published var favoriteWords: Set<String> = [] // Set of wordIds that are favorited
    
    private let userDefaults = UserDefaults.standard
    private let completedLectionsKey = "completedLections"
    private let completedSectionsKey = "completedSections"
    private let favoriteWordsKey = "favoriteWords"
    
    init() {
        loadData()
        loadCompletedStates()
        loadFavoriteWords()
    }
    
    func loadData() {
        // Load lections
        if let url = Bundle.main.url(forResource: "lections", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let lectionsData = try? JSONDecoder().decode(LectionsData.self, from: data) {
            self.lections = lectionsData.lections
        }
        
        // Load words
        if let url = Bundle.main.url(forResource: "words", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let wordsData = try? JSONDecoder().decode(WordsData.self, from: data) {
            for sectionWords in wordsData.words {
                wordsBySection[sectionWords.sectionId] = sectionWords.words
            }
        }
        
        // Load Verben mit Präpositionen
        if let url = Bundle.main.url(forResource: "verben_mit_prapositionen", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let verbenData = try? JSONDecoder().decode(WordsData.self, from: data) {
            for sectionWords in verbenData.words {
                wordsBySection[sectionWords.sectionId] = sectionWords.words
            }
        }
        
        // Load Adjektive mit Präpositionen
        if let url = Bundle.main.url(forResource: "adjektive_mit_prapositionen", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let adjektiveData = try? JSONDecoder().decode(WordsData.self, from: data) {
            for sectionWords in adjektiveData.words {
                wordsBySection[sectionWords.sectionId] = sectionWords.words
            }
        }
    }
    
    func getWords(for sectionId: String) -> [Word] {
        return wordsBySection[sectionId] ?? []
    }
    
    func getLectionAndSection(for sectionId: String) -> (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)? {
        // Handle VERBEN sections
        if sectionId.hasPrefix("VERBEN_") {
            let preposition = String(sectionId.dropFirst(7)) // Remove "VERBEN_" prefix
            return (lectionTitle: "Verben mit Präpositionen", sectionTitle: preposition, lectionNumber: "", sectionLetter: "")
        }
        
        // Handle ADJEKTIVE sections
        if sectionId.hasPrefix("ADJEKTIVE_") {
            let preposition = String(sectionId.dropFirst(10)) // Remove "ADJEKTIVE_" prefix
            return (lectionTitle: "Adjektive mit Präpositionen", sectionTitle: preposition, lectionNumber: "", sectionLetter: "")
        }
        
        // Handle regular lection sections
        for lection in lections {
            if let section = lection.sections.first(where: { $0.id == sectionId }) {
                // Extract lection number (first character(s) before letter)
                let lectionNumber = String(lection.id)
                
                // Extract section letter (last character)
                let sectionLetter = sectionId.last?.uppercased() ?? ""
                
                return (lectionTitle: lection.title, sectionTitle: section.title, lectionNumber: lectionNumber, sectionLetter: sectionLetter)
            }
        }
        return nil
    }
    
    func updateTranslation(for wordId: String, in sectionId: String, translation: String) {
        guard var words = wordsBySection[sectionId] else { return }
        if let index = words.firstIndex(where: { $0.id == wordId }) {
            words[index].translation = translation
            // Assign back to trigger @Published change notification
            wordsBySection[sectionId] = words
            // Force a change notification by toggling the dictionary
            // This ensures SwiftUI detects the change even if the dictionary reference is the same
            objectWillChange.send()
        }
    }
    
    func toggleWordChecked(wordId: String, in sectionId: String) {
        if checkedWords[sectionId] == nil {
            checkedWords[sectionId] = []
        }
        
        if var checked = checkedWords[sectionId] {
            if checked.contains(wordId) {
                checked.remove(wordId)
            } else {
                checked.insert(wordId)
            }
            checkedWords[sectionId] = checked
            updateSectionCompletion(sectionId: sectionId)
        }
    }
    
    func toggleAllWords(in sectionId: String) {
        let words = getWords(for: sectionId)
        let allWordIds = Set(words.map { $0.id })
        let currentChecked = checkedWords[sectionId] ?? Set<String>()
        
        if allWordIds.isSubset(of: currentChecked) {
            // All are selected, unselect all
            checkedWords[sectionId] = Set<String>()
        } else {
            // Select all words
            checkedWords[sectionId] = allWordIds
        }
        updateSectionCompletion(sectionId: sectionId)
    }
    
    func isWordChecked(wordId: String, in sectionId: String) -> Bool {
        return checkedWords[sectionId]?.contains(wordId) ?? false
    }
    
    func toggleSectionCompleted(sectionId: String) {
        if completedSections.contains(sectionId) {
            completedSections.remove(sectionId)
        } else {
            completedSections.insert(sectionId)
        }
        saveCompletedStates()
    }
    
    func isSectionCompleted(sectionId: String) -> Bool {
        return completedSections.contains(sectionId)
    }
    
    func toggleLectionCompleted(lectionId: Int) {
        // Find the lection
        guard let lection = lections.first(where: { $0.id == lectionId }) else { return }
        
        let sectionIds = Set(lection.sections.map { $0.id })
        
        if completedLections.contains(lectionId) {
            // Unchecking: unselect all sections in this lection
            completedLections.remove(lectionId)
            for sectionId in sectionIds {
                completedSections.remove(sectionId)
            }
        } else {
            // Checking: mark lection and all sections as completed
            completedLections.insert(lectionId)
            for sectionId in sectionIds {
                completedSections.insert(sectionId)
            }
        }
        saveCompletedStates()
    }
    
    func isLectionCompleted(lectionId: Int) -> Bool {
        return completedLections.contains(lectionId)
    }
    
    func toggleAllLections() {
        let allLectionIds = Set(lections.map { $0.id })
        let allSectionIds = Set(lections.flatMap { $0.sections.map { $0.id } })
        let allSectionsIncludingVerben = allSectionIds.union(verbenSectionIds)
        
        let allLectionsCompleted = allLectionIds.isSubset(of: completedLections)
        let allVerbenCompleted = verbenSectionIds.isSubset(of: completedSections)
        
        if allLectionsCompleted && allVerbenCompleted {
            // All are selected, unselect all
            completedLections.removeAll()
            completedSections.removeAll()
        } else {
            // Select all lections, sections, and VERBEN sections
            completedLections = allLectionIds
            completedSections = allSectionsIncludingVerben
        }
        saveCompletedStates()
    }
    
    func areAllLectionsCompleted() -> Bool {
        guard !lections.isEmpty else { return false }
        let allLectionIds = Set(lections.map { $0.id })
        let allLectionsCompleted = allLectionIds.isSubset(of: completedLections)
        let allVerbenCompleted = verbenSectionIds.isSubset(of: completedSections)
        return allLectionsCompleted && allVerbenCompleted
    }
    
    // VERBEN sections IDs
    private var verbenSectionIds: Set<String> {
        return [
            "VERBEN_an", "VERBEN_auf", "VERBEN_aus", "VERBEN_bei", "VERBEN_bis",
            "VERBEN_durch", "VERBEN_für", "VERBEN_gegen", "VERBEN_in", "VERBEN_mit",
            "VERBEN_nach", "VERBEN_über", "VERBEN_um", "VERBEN_unter", "VERBEN_von",
            "VERBEN_vor", "VERBEN_zu"
        ]
    }
    
    func toggleVerbenCompleted() {
        let allCompleted = verbenSectionIds.isSubset(of: completedSections)
        
        if allCompleted {
            // Unchecking: unselect all VERBEN sections
            for sectionId in verbenSectionIds {
                completedSections.remove(sectionId)
            }
        } else {
            // Checking: mark all VERBEN sections as completed
            for sectionId in verbenSectionIds {
                completedSections.insert(sectionId)
            }
        }
        saveCompletedStates()
    }
    
    func isVerbenCompleted() -> Bool {
        return verbenSectionIds.isSubset(of: completedSections)
    }
    
    func hasAnyLectionCompleted() -> Bool {
        guard !lections.isEmpty else { return false }
        return lections.contains { isLectionCompleted(lectionId: $0.id) } ||
               lections.flatMap { $0.sections }.contains { isSectionCompleted(sectionId: $0.id) }
    }
    
    func hasAnyVerbenCompleted() -> Bool {
        return verbenSectionIds.contains { completedSections.contains($0) }
    }
    
    // ADJEKTIVE sections IDs
    private var adjektiveSectionIds: Set<String> {
        return [
            "ADJEKTIVE_an", "ADJEKTIVE_auf", "ADJEKTIVE_bei", "ADJEKTIVE_für",
            "ADJEKTIVE_gegenüber", "ADJEKTIVE_in", "ADJEKTIVE_mit", "ADJEKTIVE_nach",
            "ADJEKTIVE_über", "ADJEKTIVE_um", "ADJEKTIVE_von", "ADJEKTIVE_vor",
            "ADJEKTIVE_zu"
        ]
    }
    
    func toggleAdjektiveCompleted() {
        let allCompleted = adjektiveSectionIds.isSubset(of: completedSections)
        
        if allCompleted {
            // Unchecking: unselect all ADJEKTIVE sections
            for sectionId in adjektiveSectionIds {
                completedSections.remove(sectionId)
            }
        } else {
            // Checking: mark all ADJEKTIVE sections as completed
            for sectionId in adjektiveSectionIds {
                completedSections.insert(sectionId)
            }
        }
        saveCompletedStates()
    }
    
    func isAdjektiveCompleted() -> Bool {
        return adjektiveSectionIds.isSubset(of: completedSections)
    }
    
    func hasAnyAdjektiveCompleted() -> Bool {
        return adjektiveSectionIds.contains { completedSections.contains($0) }
    }
    
    func getWordOfTheDay() -> Word? {
        let userDefaults = UserDefaults.standard
        
        // Word of the day is always enabled
        // Get selected sections
        let selectedSectionsString = userDefaults.string(forKey: "wordOfTheDaySelectedSections") ?? ""
        let selectedSectionIds: Set<String>
        
        if selectedSectionsString.isEmpty {
            // Empty means default to section 1A
            selectedSectionIds = Set(["1A"])
        } else {
            // Parse comma-separated section IDs
            selectedSectionIds = Set(selectedSectionsString.split(separator: ",").map { String($0) })
        }
        
        // Filter words from selected sections only
        var eligibleWords: [Word] = []
        for (sectionId, words) in wordsBySection {
            if selectedSectionIds.contains(sectionId) {
                eligibleWords.append(contentsOf: words)
            }
        }
        
        guard !eligibleWords.isEmpty else { return nil }
        
        // Get periodicity setting
        let periodicity = userDefaults.string(forKey: "wordOfTheDayPeriodicity") ?? "24_hours"
        let hoursPerPeriod: Int = periodicity == "12_hours" ? 12 : 24
        
        // Calculate period index based on periodicity
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate hours since start of year
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        let hoursSinceStartOfYear = calendar.dateComponents([.hour], from: startOfYear, to: now).hour ?? 0
        
        // Calculate period index (e.g., for 24 hours: period 0 = day 1, period 1 = day 2, etc.)
        let periodIndex = hoursSinceStartOfYear / hoursPerPeriod
        
        // Use period index to select word deterministically
        let wordIndex = periodIndex % eligibleWords.count
        
        return eligibleWords[wordIndex]
    }
    
    private func updateSectionCompletion(sectionId: String) {
        let words = getWords(for: sectionId)
        let checkedCount = checkedWords[sectionId]?.count ?? 0
        
        // Mark as completed if all words are checked
        if !words.isEmpty && checkedCount == words.count {
            if !completedSections.contains(sectionId) {
                completedSections.insert(sectionId)
                saveCompletedStates()
            }
        } else {
            // Optionally remove from completed if not all words are checked
            // Uncomment if you want sections to auto-uncomplete when words are unchecked
            // completedSections.remove(sectionId)
        }
    }
    
    // MARK: - Persistence
    
    private func saveCompletedStates() {
        // Convert Sets to Arrays for UserDefaults storage
        let lectionsArray = Array(completedLections)
        let sectionsArray = Array(completedSections)
        
        userDefaults.set(lectionsArray, forKey: completedLectionsKey)
        userDefaults.set(sectionsArray, forKey: completedSectionsKey)
    }
    
    private func loadCompletedStates() {
        // Load lections
        if let lectionsArray = userDefaults.array(forKey: completedLectionsKey) as? [Int] {
            completedLections = Set(lectionsArray)
        }
        
        // Load sections
        if let sectionsArray = userDefaults.array(forKey: completedSectionsKey) as? [String] {
            completedSections = Set(sectionsArray)
        }
    }
    
    private func loadFavoriteWords() {
        if let favoriteWordsArray = userDefaults.array(forKey: favoriteWordsKey) as? [String] {
            favoriteWords = Set(favoriteWordsArray)
        }
    }
    
    private func saveFavoriteWords() {
        let favoriteWordsArray = Array(favoriteWords)
        userDefaults.set(favoriteWordsArray, forKey: favoriteWordsKey)
    }
    
    // MARK: - Favorites Functions
    
    func toggleFavorite(wordId: String) {
        if favoriteWords.contains(wordId) {
            favoriteWords.remove(wordId)
        } else {
            favoriteWords.insert(wordId)
        }
        saveFavoriteWords()
    }
    
    func isFavorite(wordId: String) -> Bool {
        return favoriteWords.contains(wordId)
    }
    
    func getFavoriteWords() -> [Word] {
        var favoriteWordsList: [Word] = []
        for (_, words) in wordsBySection {
            for word in words {
                if favoriteWords.contains(word.id) {
                    favoriteWordsList.append(word)
                }
            }
        }
        return favoriteWordsList
    }
    
    func getSectionId(for wordId: String) -> String? {
        for (sectionId, words) in wordsBySection {
            if words.contains(where: { $0.id == wordId }) {
                return sectionId
            }
        }
        return nil
    }
    
    func getGroupType(for sectionId: String) -> FavoriteGroupType {
        if sectionId.hasPrefix("VERBEN_") {
            return .verbs
        }
        // Check if it's an adjective section (you may need to adjust this based on your data structure)
        // For now, assume regular lection sections are general words
        return .generalWords
    }
    
    enum FavoriteGroupType {
        case generalWords // Green
        case verbs // Blue
        case adjectives // Purple
        
        var color: Color {
            switch self {
            case .generalWords:
                return Color("AppGreen")
            case .verbs:
                return Color("AppBlue")
            case .adjectives:
                return Color.purple
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .generalWords:
                return Color("AppGreen").opacity(0.08)
            case .verbs:
                return Color("AppBlue").opacity(0.08)
            case .adjectives:
                return Color.purple.opacity(0.08)
            }
        }
    }
    
    func getDominantGroupType(for favoriteWords: [Word]) -> FavoriteGroupType {
        var groupCounts: [FavoriteGroupType: Int] = [:]
        
        for word in favoriteWords {
            if let sectionId = getSectionId(for: word.id) {
                let groupType = getGroupType(for: sectionId)
                groupCounts[groupType, default: 0] += 1
            }
        }
        
        // Return the most common group type, or default to generalWords
        if let dominantGroup = groupCounts.max(by: { $0.value < $1.value })?.key {
            return dominantGroup
        }
        
        return .generalWords
    }
    
    // MARK: - Reset Functions
    
    func resetAllData() {
        // Clear checked words
        checkedWords.removeAll()
        
        // Clear completed sections and lections
        completedSections.removeAll()
        completedLections.removeAll()
        
        // Clear favorite words
        favoriteWords.removeAll()
        saveFavoriteWords()
        
        // Reload words data to reset translations to original values
        wordsBySection.removeAll()
        
        // Reload regular words
        if let url = Bundle.main.url(forResource: "words", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let wordsData = try? JSONDecoder().decode(WordsData.self, from: data) {
            for sectionWords in wordsData.words {
                wordsBySection[sectionWords.sectionId] = sectionWords.words
            }
        }
        
        // Reload Verben mit Präpositionen
        if let url = Bundle.main.url(forResource: "verben_mit_prapositionen", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let verbenData = try? JSONDecoder().decode(WordsData.self, from: data) {
            for sectionWords in verbenData.words {
                wordsBySection[sectionWords.sectionId] = sectionWords.words
            }
        }
        
        // Reload Adjektive mit Präpositionen
        if let url = Bundle.main.url(forResource: "adjektive_mit_prapositionen", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let adjektiveData = try? JSONDecoder().decode(WordsData.self, from: data) {
            for sectionWords in adjektiveData.words {
                wordsBySection[sectionWords.sectionId] = sectionWords.words
            }
        }
        
        // Reset spaced repetition data
        SpacedRepetitionService.shared.resetAllStudyData()
        
        // Save cleared states
        saveCompletedStates()
        
        // Reset welcome video flag to show welcome screen again
        userDefaults.set(false, forKey: "hasSeenWelcomeVideo")
    }
}

