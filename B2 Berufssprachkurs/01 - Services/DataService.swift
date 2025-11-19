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
    
    // Store previous state before "select all" to restore when unchecking
    private var previousCompletedLections: Set<Int>?
    private var previousCompletedSections: Set<String>?
    private var previousCheckedWords: [String: Set<String>]? // sectionId: Set<wordId>
    
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
    }
    
    func getWords(for sectionId: String) -> [Word] {
        return wordsBySection[sectionId] ?? []
    }
    
    func getLectionAndSection(for sectionId: String) -> (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)? {
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
            // All are selected, restore previous state
            if let previousWords = previousCheckedWords?[sectionId] {
                checkedWords[sectionId] = previousWords
            } else {
                checkedWords[sectionId] = Set<String>()
            }
            
            // Clear saved state for this section
            if var previous = previousCheckedWords {
                previous.removeValue(forKey: sectionId)
                previousCheckedWords = previous.isEmpty ? nil : previous
            }
        } else {
            // Save current state before selecting all
            if previousCheckedWords == nil {
                previousCheckedWords = [:]
            }
            previousCheckedWords?[sectionId] = currentChecked
            
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
        if completedLections.contains(lectionId) {
            completedLections.remove(lectionId)
        } else {
            completedLections.insert(lectionId)
        }
        saveCompletedStates()
    }
    
    func isLectionCompleted(lectionId: Int) -> Bool {
        return completedLections.contains(lectionId)
    }
    
    func toggleAllLections() {
        let allLectionIds = Set(lections.map { $0.id })
        let allSectionIds = Set(lections.flatMap { $0.sections.map { $0.id } })
        
        if allLectionIds.isSubset(of: completedLections) {
            // All are selected, restore previous state
            if let previousLections = previousCompletedLections {
                completedLections = previousLections
            } else {
                completedLections.removeAll()
            }
            
            if let previousSections = previousCompletedSections {
                completedSections = previousSections
            } else {
                completedSections.removeAll()
            }
            
            // Clear saved state
            previousCompletedLections = nil
            previousCompletedSections = nil
        } else {
            // Save current state before selecting all
            previousCompletedLections = completedLections
            previousCompletedSections = completedSections
            
            // Select all lections and sections
            completedLections = allLectionIds
            completedSections = allSectionIds
        }
        saveCompletedStates()
    }
    
    func areAllLectionsCompleted() -> Bool {
        guard !lections.isEmpty else { return false }
        let allLectionIds = Set(lections.map { $0.id })
        return allLectionIds.isSubset(of: completedLections)
    }
    
    func getWordOfTheDay() -> Word? {
        var allWords: [Word] = []
        for sectionWords in wordsBySection.values {
            allWords.append(contentsOf: sectionWords)
        }
        
        guard !allWords.isEmpty else { return nil }
        
        // Use day of year as index for consistent daily word
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % allWords.count
        
        return allWords[index]
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
}

