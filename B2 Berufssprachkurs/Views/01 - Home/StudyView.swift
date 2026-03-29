//
//  StudyView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData

struct StudyItem {
    let wordId: String
    let sectionId: String
    let germanWord: String // German word (always shown on back)
    let synonym: String? // Optional synonym
    let explanation: String? // Optional explanation
    let translation: String? // Optional translation
    let quiz: String? // For VERBEN sections: quiz sentence
    let example: String? // For VERBEN sections: example sentence
    let isVerbenSection: Bool // Whether this is a VERBEN section
}

struct StudyView: View {
    @ObservedObject var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    
    // Filtering parameters
    let filterBySectionId: String? // If provided, only load from this section
    let studyAllMode: Bool // If true, load all words (ignore checked filters)
    let favoritesOnly: Bool // If true, only load favorite words
    let categoryFilter: String? // If provided, only load sections with this prefix (e.g., "VERBEN_", "ADJEKTIVE_")
    
    private let spacedRepetition = SpacedRepetitionService.shared
    @Query(sort: \WordProgress.wordId) private var wordProgressRecords: [WordProgress]
    @State private var currentIndex = 0
    @State private var studyItems: [StudyItem] = []
    @State private var isReversed = false // When true, word is on front
    @State private var cardFlipped = false // Track if card should start flipped
    @State private var flashColor: Color? = nil // Track flash color for screen flash
    @State private var cardsAnswered = 0 // Track number of cards answered in this session
    @State private var currentContentType: ContentType = .translation // Current content type shown on card
    @State private var autoMode = true // When ON, every new card resets to first available content type
    @State private var showTranslationMissingAlert = false
    @State private var buttonFeedback: ButtonFeedback? = nil // Track button press feedback for color indication
    @State private var studySessionMetricsRecorded = false
    @State private var showFavoriteLimitPaywall = false
    @Namespace private var cardNamespace
    
    // Enum for button feedback
    enum ButtonFeedback {
        case correct
        case wrong
    }
    
    // Content type enum for switching between synonym, explanation, translation
    enum ContentType: String, CaseIterable {
        case explanation
        case translation
        case synonym
        
        // Custom order for display: Erklärung, Übersetzung, Synonym
        static var displayOrder: [ContentType] {
            return [.explanation, .translation, .synonym]
        }
    }
    
    // Stack type enum for determining color scheme
    enum StackType {
        case generalWords // Green
        case verbs // Blue
        case adjectives // Purple
        case favorites // Yellow
        case myWords // Red (user vocabulary)
        
        var accentColor: Color {
            switch self {
            case .generalWords:
                return Color("AppGreen")
            case .verbs:
                return Color("AppBlue")
            case .adjectives:
                return Color("AppPurple")
            case .favorites:
                return Color("AppYellow")
            case .myWords:
                return Color("AppRed")
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .generalWords:
                return Color("AppGreenLight")
            case .verbs:
                return Color("AppBlueLight")
            case .adjectives:
                return Color("AppPurple").opacity(0.08)
            case .favorites:
                return Color("AppYellow").opacity(0.08)
            case .myWords:
                return Color("AppRed").opacity(0.08)
            }
        }
    }
    
    // Determine stack type based on study items
    private var stackType: StackType {
        if filterBySectionId == DataService.userMyWordsSectionId {
            return .myWords
        }
        if studyItems.isEmpty {
            // Default to general words if no items
            return .generalWords
        }
        
        // Check if we're filtering by a specific section
        if let sectionId = filterBySectionId {
            if sectionId.hasPrefix("VERBEN_") {
                return .verbs
            }
            if sectionId.hasPrefix("ADJEKTIVE_") {
                return .adjectives
            }
        }
        
        // Check category filter
        if let categoryFilter = categoryFilter {
            if categoryFilter == "VERBEN_" {
                return .verbs
            }
            if categoryFilter == "ADJEKTIVE_" {
                return .adjectives
            }
        }
        
        // Check if all items are VERBEN sections
        let allVerben = studyItems.allSatisfy { $0.isVerbenSection }
        if allVerben {
            return .verbs
        }
        
        // Check if all items are from ADJEKTIVE sections
        let allAdjektive = studyItems.allSatisfy { $0.sectionId.hasPrefix("ADJEKTIVE_") }
        if allAdjektive {
            return .adjectives
        }
        
        // Default to general words
        return .generalWords
    }
    
    // Track study sessions for rating prompts
    @AppStorage("studySessionCount") private var studySessionCount = 0
    @ObservedObject private var ratingManager = RatingManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    private var isPremiumActive: Bool {
        subscriptionManager.isPremiumActive
    }
    
    init(dataService: DataService, filterBySectionId: String? = nil, studyAllMode: Bool = false, favoritesOnly: Bool = false, categoryFilter: String? = nil) {
        self.dataService = dataService
        self.filterBySectionId = filterBySectionId
        self.studyAllMode = studyAllMode
        self.favoritesOnly = favoritesOnly
        self.categoryFilter = categoryFilter
    }

    private var progressTranslationById: [String: String] {
        Dictionary(uniqueKeysWithValues: wordProgressRecords.map { ($0.wordId, $0.translation) })
    }

    private var wordProgressSyncFingerprint: String {
        wordProgressRecords
            .sorted { $0.wordId < $1.wordId }
            .map { "\($0.wordId)|\($0.translation)|\($0.lastUpdated.timeIntervalSince1970)" }
            .joined(separator: "#")
    }

    /// User-edited translation from SwiftData, falling back to legacy `Word.translation` if present.
    private func translationForStudy(for word: Word) -> String? {
        if let raw = progressTranslationById[word.id] {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return raw }
        }
        let legacy = word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
        return legacy.isEmpty ? nil : word.translation
    }

    private func cardCountLabel(count: Int) -> String {
        let key = count == 1 ? Localizable.card : Localizable.cards
        return "\(count) \(Localizable.string(key))"
    }

    private func loadStudyItems() {
        var items: [StudyItem] = []
        
        // Determine which sections to process
        var sectionsToProcess: [(section: Section, lection: Lection?)] = []
        
        if let sectionId = filterBySectionId {
            if sectionId == DataService.userMyWordsSectionId {
                if !dataService.userCustomWords.isEmpty {
                    sectionsToProcess.append((section: Section(id: sectionId, title: ""), lection: nil))
                }
            } else {
                // From section view: only process the specified section
                // Try regular sections first
                for lection in dataService.lections {
                    if let section = lection.sections.first(where: { $0.id == sectionId }) {
                        if !isPremiumActive,
                           !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                            break
                        }
                        sectionsToProcess.append((section: section, lection: lection))
                        break
                    }
                }
                // If not found in regular sections, check VERBEN sections
                if sectionsToProcess.isEmpty && sectionId.hasPrefix("VERBEN_") {
                    if !isPremiumActive,
                       !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(sectionId) {
                        // Free tier: only **an** is reachable from UI; block other VERBEN deep links.
                    } else if let words = dataService.wordsBySection[sectionId], !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "VERBEN_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
                // Also check ADJEKTIVE sections
                if sectionsToProcess.isEmpty && sectionId.hasPrefix("ADJEKTIVE_") {
                    if !isPremiumActive,
                       !DataService.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(sectionId) {
                        // Free tier: only **an** is reachable from UI; block other ADJEKTIVE deep links.
                    } else if let words = dataService.wordsBySection[sectionId], !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "ADJEKTIVE_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
            }
        } else {
            // From home view: process sections based on category filter
            if let categoryFilter = categoryFilter {
                // Filter by category prefix (e.g., "VERBEN_", "ADJEKTIVE_")
                if categoryFilter == "VERBEN_" || categoryFilter == "ADJEKTIVE_" {
                    // Process only sections with this prefix
                    for (sectionId, words) in dataService.wordsBySection where sectionId.hasPrefix(categoryFilter) {
                        if categoryFilter == "VERBEN_",
                           !isPremiumActive,
                           !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(sectionId) {
                            continue
                        }
                        if categoryFilter == "ADJEKTIVE_",
                           !isPremiumActive,
                           !DataService.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(sectionId) {
                            continue
                        }
                        if !words.isEmpty {
                            let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: categoryFilter, with: ""))
                            sectionsToProcess.append((section: section, lection: nil))
                        }
                    }
                }
            } else if favoritesOnly {
                // Favorites mode: process all sections (regular + VERBEN + ADJEKTIVE)
                // Process regular sections from lections
                for lection in dataService.lections {
                    if !isPremiumActive,
                       !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                        continue
                    }
                    for section in lection.sections {
                        sectionsToProcess.append((section: section, lection: lection))
                    }
                }
                // Also process VERBEN sections from wordsBySection
                for (sectionId, words) in dataService.wordsBySection where sectionId.hasPrefix("VERBEN_") {
                    if !isPremiumActive,
                       !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(sectionId) {
                        continue
                    }
                    if !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "VERBEN_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
                // Also process ADJEKTIVE sections from wordsBySection
                for (sectionId, words) in dataService.wordsBySection where sectionId.hasPrefix("ADJEKTIVE_") {
                    if !isPremiumActive,
                       !DataService.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(sectionId) {
                        continue
                    }
                    if !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "ADJEKTIVE_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
                if !dataService.userCustomWords.isEmpty {
                    sectionsToProcess.append((
                        section: Section(id: DataService.userMyWordsSectionId, title: ""),
                        lection: nil
                    ))
                }
            } else {
                // General words mode: process only regular sections from lections (no VERBEN, no ADJEKTIVE)
                for lection in dataService.lections {
                    if !isPremiumActive,
                       !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                        continue
                    }
                    for section in lection.sections {
                        sectionsToProcess.append((section: section, lection: lection))
                    }
                }
            }
        }
        
        // Process each section
        for (section, lection) in sectionsToProcess {
            let allWords = dataService.getWords(for: section.id)
            
            // Filter words based on study mode
            let wordsToProcess: [Word]
            if favoritesOnly {
                // Favorites mode: only include favorite words
                wordsToProcess = allWords.filter { dataService.isFavorite(wordId: $0.id) }
            } else if studyAllMode {
                // Study all mode: include all words
                wordsToProcess = allWords
            } else if filterBySectionId == nil {
                // From home/general words view: if section or lection is checked, include ALL words from that section
                // Otherwise, only include checked words
                let isSectionCompleted = dataService.isSectionCompleted(sectionId: section.id)
                let isLectionCompleted = lection != nil ? dataService.isLectionCompleted(lectionId: lection!.id) : false
                
                if isSectionCompleted || isLectionCompleted {
                    // Section or lection is checked: include ALL words from this section
                    wordsToProcess = allWords
                } else {
                    // Section is not checked: only include individually checked words
                    let checkedWordIds = dataService.checkedWords[section.id] ?? Set<String>()
                    wordsToProcess = allWords.filter { checkedWordIds.contains($0.id) }
                }
            } else {
                // From section view: filter by checked words
                let checkedWordIds = dataService.checkedWords[section.id] ?? Set<String>()
                wordsToProcess = allWords.filter { checkedWordIds.contains($0.id) }
            }
            
            // Check if this is a VERBEN or ADJEKTIVE section
            let isVerbenSection = section.id.hasPrefix("VERBEN_")
            let isAdjektiveSection = section.id.hasPrefix("ADJEKTIVE_")
            
            // Process all words - include if they have at least one content type available
            for word in wordsToProcess {
                // For VERBEN sections: include if they have quiz/example OR translation
                if isVerbenSection {
                    let hasQuizAndExample = word.quiz?.isEmpty == false && word.example?.isEmpty == false
                    let explanationTrimmed = word.explanation?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let explanationOpt = (explanationTrimmed?.isEmpty == false) ? word.explanation : nil
                    let hasExample = word.example?.isEmpty == false
                    let translation = translationForStudy(for: word)
                    let hasTranslation = translation != nil
                    // Bundle JSON often leaves `quiz` empty while `example` / `explanation` are filled.
                    let hasVerbenStudyContent = hasQuizAndExample || hasTranslation || hasExample || explanationOpt != nil
                    
                    if hasVerbenStudyContent {
                        items.append(StudyItem(
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german,
                            synonym: nil,
                            explanation: explanationOpt,
                            translation: translation,
                            quiz: word.quiz,
                            example: word.example,
                            isVerbenSection: true
                        ))
                    }
                } else if isAdjektiveSection {
                    // For ADJEKTIVE sections: include if they have translation, synonym, explanation, or example
                    let synonym = word.synonyms?.first
                    let explanation = word.explanation?.isEmpty == false ? word.explanation : nil
                    let translation = translationForStudy(for: word)
                    let example = word.example?.isEmpty == false ? word.example : nil
                    
                    if synonym != nil || explanation != nil || translation != nil || example != nil {
                        items.append(StudyItem(
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german,
                            synonym: synonym,
                            explanation: explanation,
                            translation: translation,
                            quiz: nil,
                            example: example,
                            isVerbenSection: false
                        ))
                    }
                } else {
                    // For regular sections: include if they have at least one content type
                    let synonym = word.synonyms?.first
                    let explanation = word.explanation?.isEmpty == false ? word.explanation : nil
                    let translation = translationForStudy(for: word)
                    let example = word.example?.isEmpty == false ? word.example : nil
                    
                    // Only include if at least one content type is available
                    if synonym != nil || explanation != nil || translation != nil {
                        items.append(StudyItem(
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german,
                            synonym: synonym,
                            explanation: explanation,
                            translation: translation,
                            quiz: nil,
                            example: example,
                            isVerbenSection: false
                        ))
                    }
                }
            }
        }
        
        // Prioritize cards using spaced repetition (use translation mode as default for unified view)
        let wordIds = items.map { $0.wordId }
        let prioritizedIds = spacedRepetition.getPrioritizedCards(wordIds: wordIds, mode: .translations)
        
        // Reorder items based on priority
        var prioritizedItems: [StudyItem] = []
        var itemMap: [String: StudyItem] = [:]
        for item in items {
            itemMap[item.wordId] = item
        }
        
        // Add prioritized items first
        for wordId in prioritizedIds {
            if let item = itemMap[wordId] {
                prioritizedItems.append(item)
                itemMap.removeValue(forKey: wordId)
            }
        }
        
        // Add any remaining items (shouldn't happen, but safety)
        for item in itemMap.values {
            prioritizedItems.append(item)
        }
        
        studyItems = prioritizedItems
    }
    
    var body: some View {
        ZStack {
            stackType.backgroundColor
                .ignoresSafeArea()
            
            if studyItems.isEmpty {
                StudyEmptyStateView(
                    title: emptyStateTitle,
                    message: emptyStateMessage,
                    iconName: emptyStateIcon
                )
            } else if currentIndex < studyItems.count {
                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: 0) {
                        // Header with back button, title, and restart button
                        headerView
                            .padding(.top, 8)
                        
                        Spacer()
                        
                        // Flashcard in the middle with different animation approach
                        // Variation always on frontCard (colored), Word always on backCard (gray)
                        FlashCardView2(
                            studyItem: studyItems[currentIndex],
                            currentContentType: $currentContentType,
                            cardColor: {
                                let item = studyItems[currentIndex]
                                if item.sectionId == DataService.userMyWordsSectionId {
                                    return Color("AppRed")
                                }
                                if item.isVerbenSection {
                                    return Color("AppBlue")
                                } else if item.sectionId.hasPrefix("ADJEKTIVE_") {
                                    return Color("AppPurple")
                                } else {
                                    return Color("AppGreen")
                                }
                            }(),
                            cardId: studyItems[currentIndex].wordId,
                            initialFlipped: cardFlipped, // true when reversed (shows Word first)
                            dataService: dataService,
                            buttonFeedback: $buttonFeedback,
                            onSwipeCorrect: {
                                handleCorrect()
                            },
                            onSwipeWrong: {
                                handleWrong()
                            }
                        )
                        .id("card-\(currentIndex)")
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 1.2).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 20)
                        .accessibilityLabel("Flashcard \(currentIndex + 1) of \(studyItems.count)")
                        .accessibilityHint("Tap to flip card, swipe left for wrong, swipe right for correct")
                        
                        // Wrong and Correct buttons - directly under flashcard
                        HStack(spacing: 24) {
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                // Trigger color feedback
                                buttonFeedback = .wrong
                                // Small delay to show feedback before moving to next card
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    handleWrong()
                                    buttonFeedback = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(.title3, design: .default).weight(.semibold))
                                    .foregroundColor(.red)
                                    .frame(width: 64, height: 64)
                                    .background(liquidGlassCircle)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel("Mark as incorrect")
                            .accessibilityHint("Swipe left or tap to mark this answer as wrong")
                            
                            Button(action: {
                                HapticManager.shared.mediumImpact()
                                // Trigger color feedback
                                buttonFeedback = .correct
                                // Small delay to show feedback before moving to next card
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    handleCorrect()
                                    buttonFeedback = nil
                                }
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(.title3, design: .default).weight(.semibold))
                                    .foregroundColor(.green)
                                    .frame(width: 64, height: 64)
                                    .background(liquidGlassCircle)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel("Mark as correct")
                            .accessibilityHint("Swipe right or tap to mark this answer as correct")
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                        
                        Spacer()
                    }
                    
                    // Star icon in bottom right corner of the page
                    Button(action: {
                        let wid = studyItems[currentIndex].wordId
                        if dataService.toggleFavorite(wordId: wid) {
                            HapticManager.shared.lightImpact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {}
                        } else {
                            HapticManager.shared.heavyImpact()
                            showFavoriteLimitPaywall = true
                        }
                    }) {
                        Image(systemName: dataService.isFavorite(wordId: studyItems[currentIndex].wordId) ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .foregroundColor(dataService.isFavorite(wordId: studyItems[currentIndex].wordId) ? Color("AppYellow") : .secondary)
                            .symbolEffect(.bounce, value: dataService.isFavorite(wordId: studyItems[currentIndex].wordId))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .accessibilityLabel(dataService.isFavorite(wordId: studyItems[currentIndex].wordId) ? "Remove from favorites" : "Add to favorites")
                    .accessibilityHint("Toggle favorite for this word")
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if studyItems.isEmpty {
                ToolbarItem(placement: .principal) {
                    Text(Localizable.string(Localizable.study))
                        .font(.system(.headline, design: .default).weight(.regular))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
            } else {
                ToolbarItem(placement: .principal) {
                    Text(cardCountLabel(count: studyItems.count))
                        .font(.system(.headline, design: .default).weight(.medium))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        reverseCard()
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .navigationBarSymbolStyle()
                            .foregroundColor(isReversed ? .green : .primary)
                    }
                    .accessibilityLabel(isReversed ? "Reverse mode active" : "Reverse mode inactive")
                    .accessibilityHint("Toggle to show word on front or back of card")
                    .accessibilityValue(isReversed ? "Active" : "Inactive")
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .hidesBottomBarWhenPushed(true)
        .onDisappear {
            recordStudySessionMetricsIfNeeded()
        }
        .onAppear {
            loadStudyItems()
            // Set initial flip state based on reverse mode
            cardFlipped = isReversed
            if !studyItems.isEmpty {
                currentContentType = firstAvailableContentType(for: studyItems[0])
            }
        }
        .onChange(of: currentIndex) { _, _ in
            if currentIndex < studyItems.count {
                let item = studyItems[currentIndex]
                if autoMode {
                    currentContentType = firstAvailableContentType(for: item)
                } else if !isContentTypeAvailable(currentContentType, for: item) {
                    currentContentType = firstAvailableContentType(for: item)
                }
            }
        }
        .onChange(of: dataService.wordsBySection) { _, _ in
            loadStudyItems()
            // Update current content type if translation becomes available
            if currentIndex < studyItems.count {
                let item = studyItems[currentIndex]
                if !item.isVerbenSection && currentContentType == .translation {
                    // If we're in translation mode, check if translation is now available
                    if let translation = item.translation, !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Translation is available, keep it
                    } else {
                        // Translation not available, switch to first available
                        if item.explanation != nil {
                            currentContentType = .explanation
                        } else if item.synonym != nil {
                            currentContentType = .synonym
                        }
                    }
                }
            }
        }
        .onChange(of: languageManager.currentLanguage) { _, _ in
            // Reload study items when language changes
            loadStudyItems()
        }
        .onChange(of: wordProgressSyncFingerprint) { _, _ in
            loadStudyItems()
        }
        .onChange(of: dataService.userCustomWords.count) { _, _ in
            loadStudyItems()
        }
        .onChange(of: isReversed) { _, newValue in
            // Keep card flipped when reverse mode is active
            cardFlipped = newValue
        }
        .sheet(isPresented: $showFavoriteLimitPaywall) {
            PaywallView()
        }
        .alert(
            Localizable.string(Localizable.translationNotFound),
            isPresented: $showTranslationMissingAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.translationNotFoundMessage))
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // Content type buttons row - only show buttons for available content types
            if currentIndex < studyItems.count {
                let item = studyItems[currentIndex]
                let currentCardColor: Color = {
                    if item.sectionId == DataService.userMyWordsSectionId {
                        return Color("AppRed")
                    }
                    if item.isVerbenSection {
                        return Color("AppBlue")
                    } else if item.sectionId.hasPrefix("ADJEKTIVE_") {
                        return Color("AppPurple")
                    } else {
                        return Color("AppGreen")
                    }
                }()
                
                let availableTypes = ContentType.displayOrder.filter { type in
                    isContentTypeAvailable(type, for: item)
                }
                
                // Always show badges: available types + translation (even if unavailable)
                let displayTypes: [ContentType] = {
                    var types = availableTypes
                    if !types.contains(.translation) {
                        types.append(.translation)
                    }
                    return ContentType.displayOrder.filter { types.contains($0) }
                }()
                
                if !displayTypes.isEmpty {
                    HStack(spacing: 8) {
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                autoMode.toggle()
                            }
                        }) {
                            Text(Localizable.string(Localizable.auto))
                                .font(.system(.caption, design: .default).weight(.regular).width(.expanded))
                                .foregroundColor(autoMode ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(autoMode ? currentCardColor : Color(.systemGray5))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Auto mode")
                        .accessibilityValue(autoMode ? "On" : "Off")
                        .accessibilityHint("Automatically resets to explanation for each new card")
                        
                        ForEach(displayTypes, id: \.self) { type in
                            let isSelected = currentContentType == type
                            let isAvailable = isContentTypeAvailable(type, for: item)
                            
                            Button(action: {
                                if isAvailable {
                                    HapticManager.shared.lightImpact()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentContentType = type
                                    }
                                } else {
                                    HapticManager.shared.heavyImpact()
                                    showTranslationMissingAlert = true
                                }
                            }) {
                                Text(typeButtonTitle(for: type))
                                    .font(.system(.caption, design: .default).weight(.regular).width(.expanded))
                                    .foregroundColor(
                                        !isAvailable ? .secondary.opacity(0.5) :
                                        isSelected ? .white : .primary
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                isSelected && isAvailable ? currentCardColor : Color(.systemGray5)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // Helper function to check if a content type is available for a study item
    private func isContentTypeAvailable(_ type: ContentType, for item: StudyItem) -> Bool {
        if item.isVerbenSection {
            switch type {
            case .translation:
                if let translation = item.translation {
                    return !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                return false
            case .explanation:
                if let explanation = item.explanation {
                    return !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                return false
            case .synonym:
                return false
            }
        }
        switch type {
        case .synonym:
            return item.synonym != nil
        case .explanation:
            return item.explanation != nil
        case .translation:
            // Only return true if translation is actually provided (not empty)
            if let translation = item.translation {
                return !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        }
    }
    
    // Helper function to get button title for content type
    private func typeButtonTitle(for type: ContentType) -> String {
        switch type {
        case .explanation:
            return Localizable.string(Localizable.explanation)
        case .translation:
            return Localizable.string(Localizable.translation)
        case .synonym:
            return Localizable.string(Localizable.synonym)
        }
    }
    
    /// Priority: Erklärung → Übersetzung → Synonym. Falls back to current selection if nothing is available.
    private func firstAvailableContentType(for item: StudyItem) -> ContentType {
        for type in [ContentType.explanation, .translation, .synonym] {
            if isContentTypeAvailable(type, for: item) {
                return type
            }
        }
        return currentContentType
    }
    
    private var liquidGlassCircle: some View {
        Circle()
            .fill(.regularMaterial)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var hasSelectedWordsOrSections: Bool {
        if studyAllMode {
            return true // If study all mode, we have selections
        }
        
        if let sectionId = filterBySectionId {
            // Check if any words are selected in this section
            let checkedWordIds = dataService.checkedWords[sectionId] ?? Set<String>()
            return !checkedWordIds.isEmpty || dataService.isSectionCompleted(sectionId: sectionId)
        } else {
            // Stack root (Verben / Adjektive): completion lives in `completedSections`, not in lections.
            if let categoryFilter = categoryFilter {
                if categoryFilter == "VERBEN_" {
                    return dataService.hasAnyVerbenPracticeSelection(isPremium: isPremiumActive)
                }
                if categoryFilter == "ADJEKTIVE_" {
                    return dataService.hasAnyAdjektivePracticeSelection(isPremium: isPremiumActive)
                }
            }
            // From home view: check if any sections or lections are selected (non‑Pro: lection 1 only)
            for lection in dataService.lections {
                if !isPremiumActive,
                   !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                    continue
                }
                if dataService.isLectionCompleted(lectionId: lection.id) {
                    return true
                }
                for section in lection.sections {
                    if dataService.isSectionCompleted(sectionId: section.id) {
                        return true
                    }
                    let checkedWordIds = dataService.checkedWords[section.id] ?? Set<String>()
                    if !checkedWordIds.isEmpty {
                        return true
                    }
                }
            }
            return false
        }
    }
    
    var emptyStateIcon: String {
        if !hasSelectedWordsOrSections {
            return "checkmark.circle"
        }
        return "long.text.page.and.pencil"
    }
    
    var emptyStateTitle: String {
        if !hasSelectedWordsOrSections {
            return Localizable.string(Localizable.noWordsSelected)
        }
        return Localizable.string(Localizable.translationNotFound)
    }
    
    var emptyStateMessage: String {
        if !hasSelectedWordsOrSections {
            return Localizable.string(Localizable.noWordsSelectedMessage)
        }
        return Localizable.string(Localizable.translationNotFoundMessage)
    }
    
    private func handleWrong() {
        // Record spaced repetition result (quality 0-2 for wrong answers)
        let currentItem = studyItems[currentIndex]
        // Map content type to study mode for spaced repetition tracking
        let studyMode: StudyMode = {
            switch currentContentType {
            case .synonym:
                return .synonyms
            case .explanation:
                return .explanation
            case .translation:
                return .translations
            }
        }()
        spacedRepetition.recordStudyResult(wordId: currentItem.wordId, mode: studyMode, quality: 0)
        
        // Track that user answered a card
        cardsAnswered += 1
        
        // Move to next card with different animation
        withAnimation(.easeInOut(duration: 0.4)) {
            if currentIndex < studyItems.count - 1 {
                // Move to next card
                currentIndex += 1
            } else {
                // Loop back to beginning and re-prioritize cards
                reorderStudyItems()
                currentIndex = 0
            }
            // Keep word on top if reverse mode is active
            cardFlipped = isReversed
        }
    }
    
    private func handleCorrect() {
        // Record spaced repetition result (quality 4-5 for correct answers)
        let currentItem = studyItems[currentIndex]
        // Map content type to study mode for spaced repetition tracking
        let studyMode: StudyMode = {
            switch currentContentType {
            case .synonym:
                return .synonyms
            case .explanation:
                return .explanation
            case .translation:
                return .translations
            }
        }()
        spacedRepetition.recordStudyResult(wordId: currentItem.wordId, mode: studyMode, quality: 4)
        
        // Track that user answered a card
        cardsAnswered += 1
        
        // Move to next card with different animation
        withAnimation(.easeInOut(duration: 0.4)) {
            if currentIndex < studyItems.count - 1 {
                // Move to next card
                currentIndex += 1
            } else {
                // Loop back to beginning and re-prioritize cards
                reorderStudyItems()
                currentIndex = 0
            }
            // Keep word on top if reverse mode is active
            cardFlipped = isReversed
        }
    }
    
    /// Reorder study items based on spaced repetition priority
    private func reorderStudyItems() {
        let wordIds = studyItems.map { $0.wordId }
        // Use translation mode as default for unified view
        let prioritizedIds = spacedRepetition.getPrioritizedCards(wordIds: wordIds, mode: .translations)
        
        // Reorder items based on priority
        var prioritizedItems: [StudyItem] = []
        var itemMap: [String: StudyItem] = [:]
        for item in studyItems {
            itemMap[item.wordId] = item
        }
        
        // Add prioritized items first
        for wordId in prioritizedIds {
            if let item = itemMap[wordId] {
                prioritizedItems.append(item)
                itemMap.removeValue(forKey: wordId)
            }
        }
        
        // Add any remaining items
        for item in itemMap.values {
            prioritizedItems.append(item)
        }
        
        studyItems = prioritizedItems
    }
    
    private func flashScreen(color: Color) {
        withAnimation(.easeOut(duration: 0.2)) {
            flashColor = color
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.3)) {
                flashColor = nil
            }
        }
    }
    
    private func recordStudySessionMetricsIfNeeded() {
        guard !studySessionMetricsRecorded else { return }
        studySessionMetricsRecorded = true
        // Only count as a session if user answered at least 3 cards
        // This prevents counting sessions where user just opened and closed
        if cardsAnswered >= 3 {
            studySessionCount += 1
            
            // Check if we should show rating prompt
            if ratingManager.trackStudySession() {
                // Show rating prompt after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    ratingManager.requestRating()
                }
            }
        }
    }
    
    private func reverseCard() {
        // Only flip/reverse the card, don't change cards
        withAnimation(.easeInOut(duration: 0.5)) {
            isReversed.toggle() // Toggle to show word on front
            cardFlipped = isReversed // Flip card if reversed
        }
    }
    
    private func restartStudy() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentIndex = 0
            studyItems = studyItems.shuffled()
            cardFlipped = isReversed // Respect reverse mode state
        }
    }
}

// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// FlashCardView2 with different animation approach
struct FlashCardView2: View {
    let studyItem: StudyItem
    @Binding var currentContentType: StudyView.ContentType
    let cardColor: Color
    let cardId: String?
    let initialFlipped: Bool
    @ObservedObject var dataService: DataService
    @Binding var buttonFeedback: StudyView.ButtonFeedback?
    let onSwipeCorrect: (() -> Void)?
    let onSwipeWrong: (() -> Void)?
    
    @State private var showsFront = true
    @State private var halfAngle: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var thresholdReached = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var isFavorite: Bool {
        dataService.isFavorite(wordId: studyItem.wordId)
    }
    
    init(
        studyItem: StudyItem,
        currentContentType: Binding<StudyView.ContentType>,
        cardColor: Color,
        cardId: String? = nil,
        initialFlipped: Bool = false,
        dataService: DataService,
        buttonFeedback: Binding<StudyView.ButtonFeedback?>,
        onSwipeCorrect: (() -> Void)? = nil,
        onSwipeWrong: (() -> Void)? = nil
    ) {
        self.studyItem = studyItem
        self._currentContentType = currentContentType
        self.cardColor = cardColor
        self.cardId = cardId
        self.initialFlipped = initialFlipped
        self.dataService = dataService
        self._buttonFeedback = buttonFeedback
        self.onSwipeCorrect = onSwipeCorrect
        self.onSwipeWrong = onSwipeWrong
    }
    
    private let grayColor = Color(.systemGray5)
    private let swipeThreshold: CGFloat = 120
    private let rotationAmount: Double = 15
    
    // Computed properties for front text and card color
    private var frontText: String {
        if studyItem.isVerbenSection {
            // Translation → user translation; Erklärung → bundled meaning; else cloze/quiz when present; else example
            if currentContentType == .translation, let translation = studyItem.translation, !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return translation
            }
            if currentContentType == .explanation, let explanation = studyItem.explanation, !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return explanation
            }
            if let quiz = studyItem.quiz, !quiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return quiz
            }
            if let explanation = studyItem.explanation, !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return explanation
            }
            return studyItem.example ?? ""
        }
        
        switch currentContentType {
        case .synonym:
            return studyItem.synonym ?? ""
        case .explanation:
            return studyItem.explanation ?? ""
        case .translation:
            return studyItem.translation ?? ""
        }
    }
    
    // Check if we should show the placeholder message
    private var shouldShowPlaceholder: Bool {
        if studyItem.isVerbenSection {
            return false
        }
        
        if currentContentType == .translation {
            let translation = studyItem.translation ?? ""
            return translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        return false
    }
    
    // Helper function to get button title for content type
    private func typeButtonTitle(for type: StudyView.ContentType) -> String {
        switch type {
        case .explanation:
            return Localizable.string(Localizable.explanation)
        case .translation:
            return Localizable.string(Localizable.translation)
        case .synonym:
            return Localizable.string(Localizable.synonym)
        }
    }
    
    private var backText: String {
        if studyItem.isVerbenSection {
            return studyItem.example ?? ""
        }
        return studyItem.germanWord
    }
    
    
    private func performFlip() {
        if reduceMotion {
            showsFront.toggle()
            halfAngle = showsFront ? 0 : 180
            return
        }
        let target: Double = showsFront ? 180 : 0
        withAnimation(.easeIn(duration: 0.25)) {
            halfAngle = 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showsFront.toggle()
            withAnimation(.easeOut(duration: 0.25)) {
                halfAngle = target
            }
        }
    }
    
    var body: some View {
        ZStack {
            frontCard
                .opacity(showsFront ? 1 : 0)
                .accessibilityHidden(!showsFront)
            
            backCard
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsFront ? 0 : 1)
                .accessibilityHidden(showsFront)
        }
        .rotation3DEffect(.degrees(halfAngle), axis: (x: 0, y: 1, z: 0))
        .accessibilityElement(children: .contain)
        .accessibilityValue(showsFront ? "Showing front" : "Showing back")
        .offset(dragOffset)
        .rotationEffect(.degrees(reduceMotion ? 0 : dragRotation))
        .opacity(1 - min(abs(dragOffset.width) / 600.0, 0.3))
        .overlay {
            // Color tint overlay based on swipe direction or button feedback
            if abs(dragOffset.width) > 50 {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        dragOffset.width > 0 ?
                            Color.green.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3)) :
                            Color.red.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3))
                    )
                    .allowsHitTesting(false)
            } else if let feedback = buttonFeedback {
                // Show color indication for button press
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        feedback == .correct ?
                            Color.green.opacity(0.3) :
                            Color.red.opacity(0.3)
                    )
                    .allowsHitTesting(false)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    // Only allow horizontal swipes
                    let horizontalDrag = value.translation.width
                    dragOffset = CGSize(width: horizontalDrag, height: value.translation.height * 0.3)
                    
                    if !reduceMotion {
                        dragRotation = Double(horizontalDrag / 20)
                    }
                    
                    // Haptic feedback when threshold is reached
                    if abs(horizontalDrag) > swipeThreshold && !thresholdReached {
                        HapticManager.shared.mediumImpact()
                        thresholdReached = true
                    } else if abs(horizontalDrag) <= swipeThreshold && thresholdReached {
                        thresholdReached = false
                    }
                }
                .onEnded { value in
                    let horizontalDrag = value.translation.width
                    
                    if horizontalDrag > swipeThreshold {
                        // Swipe right = correct
                        HapticManager.shared.mediumImpact()
                        // Animate card off-screen to the right
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = CGSize(width: 1000, height: 0)
                            dragRotation = 30
                        }
                        // Trigger callback after animation starts
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSwipeCorrect?()
                        }
                    } else if horizontalDrag < -swipeThreshold {
                        // Swipe left = wrong
                        HapticManager.shared.lightImpact()
                        // Animate card off-screen to the left
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = CGSize(width: -1000, height: 0)
                            dragRotation = -30
                        }
                        // Trigger callback after animation starts
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSwipeWrong?()
                        }
                    } else {
                        // Snap back to center
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = .zero
                            dragRotation = 0
                        }
                        thresholdReached = false
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if dragOffset == .zero {
                        performFlip()
                    }
                }
        )
        .onChange(of: cardId) { _, _ in
            showsFront = !initialFlipped
            halfAngle = initialFlipped ? 180 : 0
            dragOffset = .zero
            dragRotation = 0
            thresholdReached = false
        }
        .onChange(of: studyItem.wordId) { _, _ in
            // Keep the user's selected content type when card changes
            // Only switch if current type is not available for the new card
            if studyItem.isVerbenSection {
                if currentContentType == .translation {
                    let translation = studyItem.translation ?? ""
                    if translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       let explanation = studyItem.explanation,
                       !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        currentContentType = .explanation
                    }
                } else if currentContentType == .explanation {
                    let explanation = studyItem.explanation ?? ""
                    if explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       let translation = studyItem.translation,
                       !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        currentContentType = .translation
                    }
                }
            } else {
                // Check if current content type is available
                var isAvailable = false
                switch currentContentType {
                case .explanation:
                    isAvailable = studyItem.explanation != nil
                case .translation:
                    isAvailable = true // Translation is always available (shows placeholder if missing)
                case .synonym:
                    isAvailable = studyItem.synonym != nil
                }
                
                if !isAvailable {
                    // Find first available content type
                    if studyItem.explanation != nil {
                        currentContentType = .explanation
                    } else if studyItem.translation != nil {
                        currentContentType = .translation
                    } else if studyItem.synonym != nil {
                        currentContentType = .synonym
                    } else {
                        // Fallback to translation (always available)
                        currentContentType = .translation
                    }
                }
                // Otherwise keep the current selection
            }
        }
        .onChange(of: initialFlipped) { _, newValue in
            let target = !newValue
            if showsFront != target {
                performFlip()
            }
        }
        .onAppear {
            showsFront = !initialFlipped
            halfAngle = initialFlipped ? 180 : 0
        }
        .id(cardId)
    }
    
    private var frontCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                cardColor.opacity(0.3),
                                cardColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                // Main content text
                if shouldShowPlaceholder {
                    Text(Localizable.string(Localizable.addTranslationToWord))
                        .font(.system(.body, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    Text(frontText)
                        .font(.system(.title2, design: .default).weight(.regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .accessibilityLabel("Card front: \(frontText)")
            .accessibilityHint("Tap to flip card")
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
    
    private var backCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                grayColor.opacity(0.3),
                                grayColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                VStack(spacing: 16) {
                    // Show German word (verb/adjective with case) above in black and bold for VERBEN and ADJEKTIVE sections
                    if studyItem.isVerbenSection || studyItem.sectionId.hasPrefix("ADJEKTIVE_") {
                        Text(studyItem.germanWord)
                            .font(.system(.title2, design: .default).weight(.regular))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Show example sentence below in gray and smaller font
                        if let example = studyItem.example, !example.isEmpty {
                            Text(example)
                                .font(.body)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        // For regular sections, show German word in bold, then example
                        Text(studyItem.germanWord)
                            .font(.system(.title2, design: .default).weight(.regular))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Show example sentence below in gray and smaller font (if available)
                        if let example = studyItem.example, !example.isEmpty {
                            Text(example)
                                .font(.body)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .accessibilityLabel("Card back: \(studyItem.germanWord)\(studyItem.example != nil ? ". Example: \(studyItem.example ?? "")" : "")")
            .accessibilityHint("Tap to flip card")
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, CustomWordEntry.self, configurations: config)
    NavigationStack {
        StudyView(dataService: DataService(), filterBySectionId: nil, studyAllMode: true)
    }
    .modelContainer(container)
}

