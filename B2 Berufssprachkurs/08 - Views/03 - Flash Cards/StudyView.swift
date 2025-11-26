//
//  StudyView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

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
    @Environment(\.dismiss) private var dismiss
    
    // Filtering parameters
    let filterBySectionId: String? // If provided, only load from this section
    let studyAllMode: Bool // If true, load all words (ignore checked filters)
    let favoritesOnly: Bool // If true, only load favorite words
    
    private let spacedRepetition = SpacedRepetitionService.shared
    @State private var currentIndex = 0
    @State private var studyItems: [StudyItem] = []
    @State private var isReversed = false // When true, word is on front
    @State private var cardFlipped = false // Track if card should start flipped
    @State private var flashColor: Color? = nil // Track flash color for screen flash
    @State private var cardsAnswered = 0 // Track number of cards answered in this session
    @State private var currentContentType: ContentType = .explanation // Current content type shown on card
    @Namespace private var cardNamespace
    
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
        
        var accentColor: Color {
            switch self {
            case .generalWords:
                return Color("AppGreen")
            case .verbs:
                return Color("AppBlue")
            case .adjectives:
                return Color.purple
            case .favorites:
                return Color.yellow
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .generalWords:
                return Color("AppGreenLight")
            case .verbs:
                return Color("AppBlueLight")
            case .adjectives:
                return Color.purple.opacity(0.08)
            case .favorites:
                return Color.yellow.opacity(0.08)
            }
        }
    }
    
    // Determine stack type based on study items
    private var stackType: StackType {
        if studyItems.isEmpty {
            // Default to general words if no items
            return .generalWords
        }
        
        // Check if all items are VERBEN sections
        let allVerben = studyItems.allSatisfy { $0.isVerbenSection }
        if allVerben {
            return .verbs
        }
        
        // Check if we're filtering by a specific section
        if let sectionId = filterBySectionId {
            if sectionId.hasPrefix("VERBEN_") {
                return .verbs
            }
            // Could add check for adjectives or favorites here in the future
        }
        
        // Default to general words
        return .generalWords
    }
    
    // Track study sessions for interstitial ads
    @AppStorage("studySessionCount") private var studySessionCount = 0
    @AppStorage("adsDisabledUntil") private var adsDisabledUntil: TimeInterval = 0
    
    private var isPremiumActive: Bool {
        let now = Date().timeIntervalSince1970
        return adsDisabledUntil > now
    }
    
    init(dataService: DataService, filterBySectionId: String? = nil, studyAllMode: Bool = false, favoritesOnly: Bool = false) {
        self.dataService = dataService
        self.filterBySectionId = filterBySectionId
        self.studyAllMode = studyAllMode
        self.favoritesOnly = favoritesOnly
    }
    
    private func loadStudyItems() {
        var items: [StudyItem] = []
        
        // Determine which sections to process
        var sectionsToProcess: [(section: Section, lection: Lection?)] = []
        
        if let sectionId = filterBySectionId {
            // From section view: only process the specified section
            // Try regular sections first
            for lection in dataService.lections {
                if let section = lection.sections.first(where: { $0.id == sectionId }) {
                    sectionsToProcess.append((section: section, lection: lection))
                    break
                }
            }
            // If not found in regular sections, check VERBEN sections
            if sectionsToProcess.isEmpty && sectionId.hasPrefix("VERBEN_") {
                if let words = dataService.wordsBySection[sectionId], !words.isEmpty {
                    let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "VERBEN_", with: ""))
                    sectionsToProcess.append((section: section, lection: nil))
                }
            }
        } else {
            // From home/verbs view: process all sections
            // Process regular sections from lections
            for lection in dataService.lections {
                for section in lection.sections {
                    sectionsToProcess.append((section: section, lection: lection))
                }
            }
            // Also process VERBEN sections from wordsBySection
            for (sectionId, words) in dataService.wordsBySection where sectionId.hasPrefix("VERBEN_") {
                if !words.isEmpty {
                    let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "VERBEN_", with: ""))
                    sectionsToProcess.append((section: section, lection: nil))
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
            
            // Check if this is a VERBEN section
            let isVerbenSection = section.id.hasPrefix("VERBEN_")
            
            // Process all words - include if they have at least one content type available
            for word in wordsToProcess {
                // For VERBEN sections: include if they have quiz/example
                if isVerbenSection {
                    if let quiz = word.quiz, !quiz.isEmpty, let example = word.example, !example.isEmpty {
                        items.append(StudyItem(
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german,
                            synonym: nil,
                            explanation: nil,
                            translation: nil,
                            quiz: quiz,
                            example: example,
                            isVerbenSection: true
                        ))
                    }
                } else {
                    // For regular sections: include if they have at least one content type
                    let synonym = word.synonyms?.first
                    let explanation = word.explanation?.isEmpty == false ? word.explanation : nil
                    let translation = word.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : word.translation
                    
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
                            example: nil,
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
                    iconName: emptyStateIcon,
                    modeTitle: Localizable.string(Localizable.study),
                    onBack: {
                        handleDismiss()
                    }
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
                            cardColor: studyItems[currentIndex].isVerbenSection ? Color("AppBlue") : Color("AppGreen"),
                            cardId: studyItems[currentIndex].wordId,
                            initialFlipped: cardFlipped, // true when reversed (shows Word first)
                            dataService: dataService,
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
                                handleWrong()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                    .frame(width: 64, height: 64)
                                    .background(liquidGlassCircle)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel("Mark as incorrect")
                            .accessibilityHint("Swipe left or tap to mark this answer as wrong")
                            
                            Button(action: {
                                HapticManager.shared.mediumImpact()
                                handleCorrect()
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.title3)
                                    .fontWeight(.semibold)
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
                        HapticManager.shared.lightImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            dataService.toggleFavorite(wordId: studyItems[currentIndex].wordId)
                        }
                    }) {
                        Image(systemName: dataService.isFavorite(wordId: studyItems[currentIndex].wordId) ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(dataService.isFavorite(wordId: studyItems[currentIndex].wordId) ? Color.yellow : .secondary)
                            .symbolEffect(.bounce, value: dataService.isFavorite(wordId: studyItems[currentIndex].wordId))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .accessibilityLabel(dataService.isFavorite(wordId: studyItems[currentIndex].wordId) ? "Remove from favorites" : "Add to favorites")
                    .accessibilityHint("Toggle favorite for this word")
                }
            }
            
            // Flash overlay
            if let flashColor = flashColor {
                flashColor
                    .ignoresSafeArea()
                    .opacity(0.3)
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadStudyItems()
            // Set initial flip state based on reverse mode
            cardFlipped = isReversed
            // Only set default if not already set (preserve user's choice)
            if currentContentType == .explanation && !studyItems.isEmpty && !studyItems[0].isVerbenSection {
                // Keep default, but don't override if user already changed it
            }
        }
        .onChange(of: currentIndex) { _, _ in
            // Keep the user's selected content type when moving to next card
            // Only switch if current type is not available for the new card
            if currentIndex < studyItems.count {
                let item = studyItems[currentIndex]
                if !item.isVerbenSection {
                    // Check if current content type is available
                    if !isContentTypeAvailable(currentContentType, for: item) {
                        // Find first available content type
                        if item.explanation != nil {
                            currentContentType = .explanation
                        } else if item.synonym != nil {
                            currentContentType = .synonym
                        } else if let translation = item.translation, !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            currentContentType = .translation
                        } else {
                            // No content available, keep current but it won't show buttons
                            // This shouldn't happen if data is correct
                        }
                    }
                    // Otherwise keep the current selection
                }
            }
        }
        .onChange(of: dataService.wordsBySection) { _, _ in
            loadStudyItems()
        }
        .onChange(of: isReversed) { _, newValue in
            // Keep card flipped when reverse mode is active
            cardFlipped = newValue
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // Back button with liquid glass style
                Button(action: {
                    HapticManager.shared.lightImpact()
                    handleDismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(liquidGlassCircle)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Back")
                .accessibilityHint("Return to previous screen")
                
                Spacer()
                
                // Title - Card count
                Text("\(studyItems.count) \(Localizable.string(Localizable.cards))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                // Reverse button with liquid glass style
                Button(action: {
                    HapticManager.shared.lightImpact()
                    reverseCard()
                }) {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(isReversed ? .green : .primary)
                        .frame(width: 44, height: 44)
                        .background(liquidGlassCircle)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(isReversed ? "Reverse mode active" : "Reverse mode inactive")
                .accessibilityHint("Toggle to show word on front or back of card")
                .accessibilityValue(isReversed ? "Active" : "Inactive")
            }
            
            // Content type buttons row - only show buttons for available content types
            if currentIndex < studyItems.count {
                let item = studyItems[currentIndex]
                let currentCardColor = item.isVerbenSection ? Color("AppBlue") : Color("AppGreen")
                if !item.isVerbenSection {
                    // Filter to only show available content types
                    let availableTypes = ContentType.displayOrder.filter { type in
                        isContentTypeAvailable(type, for: item)
                    }
                    
                    if !availableTypes.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(availableTypes, id: \.self) { type in
                                let isSelected = currentContentType == type
                                
                                Button(action: {
                                    HapticManager.shared.lightImpact()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentContentType = type
                                    }
                                }) {
                                    Text(typeButtonTitle(for: type))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(isSelected ? currentCardColor : Color(.systemGray5))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
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
            return false
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
            // From home view: check if any sections or lections are selected
            for lection in dataService.lections {
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
        return "book.closed"
    }
    
    var emptyStateTitle: String {
        if !hasSelectedWordsOrSections {
            return "Keine Wörter ausgewählt"
        }
        return "Keine Wörter verfügbar"
    }
    
    var emptyStateMessage: String {
        if !hasSelectedWordsOrSections {
            return "Wähle die Wörter mit dem Häkchen aus"
        }
        return "Bitte füge Übersetzungen, Synonyme oder Erklärungen zu den Wörtern hinzu"
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
        
        // Flash screen red
        flashScreen(color: .red)
        
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
        
        // Flash screen green
        flashScreen(color: .green)
        
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
    
    private func handleDismiss() {
        // Only count as a session if user answered at least 3 cards
        // This prevents counting sessions where user just opened and closed
        if cardsAnswered >= 3 {
            studySessionCount += 1
            
            // Show interstitial ad every 2-3 sessions (only if premium is not active)
            // This gives a good balance between revenue and user experience
            if !isPremiumActive && studySessionCount % 3 == 0 {
                // Show ad after a short delay to allow view to start dismissing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    InterstitialAdHelper.showInterstitialAd()
                }
            }
        }
        
        dismiss()
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
    let onSwipeCorrect: (() -> Void)?
    let onSwipeWrong: (() -> Void)?
    
    @State private var isFlipped = false
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
        onSwipeCorrect: (() -> Void)? = nil,
        onSwipeWrong: (() -> Void)? = nil
    ) {
        self.studyItem = studyItem
        self._currentContentType = currentContentType
        self.cardColor = cardColor
        self.cardId = cardId
        self.initialFlipped = initialFlipped
        self.dataService = dataService
        self.onSwipeCorrect = onSwipeCorrect
        self.onSwipeWrong = onSwipeWrong
    }
    
    private let grayColor = Color(.systemGray5)
    private let swipeThreshold: CGFloat = 120
    private let rotationAmount: Double = 15
    
    // Computed properties for front text and card color
    private var frontText: String {
        if studyItem.isVerbenSection {
            return studyItem.quiz ?? ""
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
    
    
    var body: some View {
        ZStack {
            frontCard
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .accessibilityHidden(isFlipped)
            
            backCard
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .accessibilityHidden(!isFlipped)
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(isFlipped ? "Showing back" : "Showing front")
        .offset(dragOffset)
        .rotationEffect(.degrees(reduceMotion ? 0 : dragRotation))
        .opacity(1 - min(abs(dragOffset.width) / 600.0, 0.3))
        .overlay {
            // Color tint overlay based on swipe direction
            if abs(dragOffset.width) > 50 {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        dragOffset.width > 0 ?
                            Color.green.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3)) :
                            Color.red.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3))
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
                    // Only flip if not dragging
                    if dragOffset == .zero {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isFlipped.toggle()
                        }
                    }
                }
        )
        .onChange(of: cardId) { _, _ in
            isFlipped = initialFlipped
            dragOffset = .zero
            dragRotation = 0
            thresholdReached = false
        }
        .onChange(of: studyItem.wordId) { _, _ in
            // Keep the user's selected content type when card changes
            // Only switch if current type is not available for the new card
            if !studyItem.isVerbenSection {
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
            withAnimation(.easeInOut(duration: 0.5)) {
                isFlipped = newValue
            }
        }
        .onAppear {
            isFlipped = initialFlipped
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
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    Text(frontText)
                        .font(.title2)
                        .fontWeight(.semibold)
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
                    Text(backText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Show German word below example for VERBEN sections
                    if studyItem.isVerbenSection {
                        Text(studyItem.germanWord)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
            }
            .accessibilityLabel("Card back: \(backText)\(studyItem.isVerbenSection ? ". German word: \(studyItem.germanWord)" : "")")
            .accessibilityHint("Tap to flip card")
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

#Preview {
    NavigationStack {
        StudyView(dataService: DataService(), filterBySectionId: nil, studyAllMode: true)
    }
}

