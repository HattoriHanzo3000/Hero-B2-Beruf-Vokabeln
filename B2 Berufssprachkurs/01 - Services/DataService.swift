//
//  DataService.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation
import Combine

@MainActor
class DataService: ObservableObject {
    @Published var lections: [Lection] = []
    @Published var wordsBySection: [String: [Word]] = [:]
    @Published var completedSections: Set<String> = []
    @Published var completedLections: Set<Int> = []
    @Published var checkedWords: [String: Set<String>] = [:] // sectionId: Set<wordId>
    
    private let userDefaults = UserDefaults.standard
    private let completedLectionsKey = "completedLections"
    private let completedSectionsKey = "completedSections"
    
    init() {
        loadData()
        loadCompletedStates()
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
            wordsBySection[sectionId] = words
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
    
    func getWordOfTheDay() -> Word? {
        let userDefaults = UserDefaults.standard
        
        // Check if word of the day is enabled
        guard userDefaults.bool(forKey: "wordOfTheDayEnabled") else {
            return nil
        }
        
        // Get selected sections
        let selectedSectionsString = userDefaults.string(forKey: "wordOfTheDaySelectedSections") ?? ""
        let selectedSectionIds: Set<String>
        
        if selectedSectionsString.isEmpty {
            // Empty means all sections
            selectedSectionIds = Set(wordsBySection.keys)
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
    
    // MARK: - Reset Functions
    
    func resetAllData() {
        // Clear checked words
        checkedWords.removeAll()
        
        // Clear completed sections and lections
        completedSections.removeAll()
        completedLections.removeAll()
        
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
        
        // Reset spaced repetition data
        SpacedRepetitionService.shared.resetAllStudyData()
        
        // Save cleared states
        saveCompletedStates()
        
        // Reset welcome video flag to show welcome screen again
        userDefaults.set(false, forKey: "hasSeenWelcomeVideo")
    }
}

