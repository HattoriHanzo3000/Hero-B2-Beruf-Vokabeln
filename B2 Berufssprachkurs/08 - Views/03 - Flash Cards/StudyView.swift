//
//  StudyView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct StudyItem {
    let front: String  // Variation (synonym, explanation, or translation)
    let back: String   // Word (German word) or example sentence
    let wordId: String
    let sectionId: String
    let germanWord: String? // For example mode: verb with preposition and case
}

struct StudyView: View {
    let mode: StudyMode
    @ObservedObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    // Filtering parameters
    let filterBySectionId: String? // If provided, only load from this section
    let studyAllMode: Bool // If true, load all words (ignore checked filters)
    
    private let spacedRepetition = SpacedRepetitionService.shared
    @State private var currentIndex = 0
    @State private var studyItems: [StudyItem] = []
    @State private var isReversed = false // When true, word is on front
    @State private var cardFlipped = false // Track if card should start flipped
    @State private var flashColor: Color? = nil // Track flash color for screen flash
    @State private var cardsAnswered = 0 // Track number of cards answered in this session
    @Namespace private var cardNamespace
    
    // Track study sessions for interstitial ads
    @AppStorage("studySessionCount") private var studySessionCount = 0
    @AppStorage("adsDisabledUntil") private var adsDisabledUntil: TimeInterval = 0
    
    private var isPremiumActive: Bool {
        let now = Date().timeIntervalSince1970
        return adsDisabledUntil > now
    }
    
    init(mode: StudyMode, dataService: DataService, filterBySectionId: String? = nil, studyAllMode: Bool = false) {
        self.mode = mode
        self.dataService = dataService
        self.filterBySectionId = filterBySectionId
        self.studyAllMode = studyAllMode
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
            // If not in study all mode and from home view, filter by checked sections/lections
            if !studyAllMode && filterBySectionId == nil {
                // From home view: only include checked sections or sections in checked lections
                let isSectionCompleted = dataService.isSectionCompleted(sectionId: section.id)
                let isLectionCompleted = lection != nil ? dataService.isLectionCompleted(lectionId: lection!.id) : false
                
                // Only include if section is checked OR lection is checked
                if !isSectionCompleted && !isLectionCompleted {
                    continue // Skip unchecked sections
                }
            }
            
            let allWords = dataService.getWords(for: section.id)
            
            // Filter words based on study mode
            let wordsToProcess: [Word]
            if studyAllMode {
                // Study all mode: include all words
                wordsToProcess = allWords
            } else {
                // Filter by checked words
                let checkedWordIds = dataService.checkedWords[section.id] ?? Set<String>()
                wordsToProcess = allWords.filter { checkedWordIds.contains($0.id) }
            }
            
            // Check if this is a VERBEN section
            let isVerbenSection = section.id.hasPrefix("VERBEN_")
            
            // Process words based on study mode
            for word in wordsToProcess {
                switch mode {
                case .synonyms:
                    // For synonyms: show all words that have synonyms
                    if let synonyms = word.synonyms, !synonyms.isEmpty {
                        // Randomly pick a synonym or use the first one
                        let synonym = synonyms.randomElement() ?? synonyms.first ?? ""
                        items.append(StudyItem(
                            front: synonym,
                            back: word.german,
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: nil
                        ))
                    }
                case .explanation:
                    // For explanation: show all words that have explanations
                    if let explanation = word.explanation, !explanation.isEmpty {
                        items.append(StudyItem(
                            front: explanation,
                            back: word.german,
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: nil
                        ))
                    }
                case .translations:
                    // For translations: only show words where translation was written
                    let translation = word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !translation.isEmpty {
                        items.append(StudyItem(
                            front: translation,
                            back: word.german,
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: nil
                        ))
                    }
                case .example:
                    // For example mode (VERBEN sections): show quiz sentence on front, example on back
                    if isVerbenSection, let quiz = word.quiz, !quiz.isEmpty, let example = word.example, !example.isEmpty {
                        items.append(StudyItem(
                            front: quiz,
                            back: example,
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german // Store German word to show below example
                        ))
                    }
                }
            }
        }
        
        // Prioritize cards using spaced repetition
        let wordIds = items.map { $0.wordId }
        let prioritizedIds = spacedRepetition.getPrioritizedCards(wordIds: wordIds, mode: mode)
        
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
            mode.backgroundColor
                .ignoresSafeArea()
            
            if studyItems.isEmpty {
                StudyEmptyStateView(
                    title: emptyStateTitle,
                    message: emptyStateMessage,
                    iconName: emptyStateIcon,
                    modeTitle: mode.title,
                    onBack: {
                        handleDismiss()
                    }
                )
            } else if currentIndex < studyItems.count {
                VStack(spacing: 0) {
                    // Header with back button, title, and restart button
                    headerView
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // Flashcard in the middle with different animation approach
                    // Variation always on frontCard (colored), Word always on backCard (gray)
                    FlashCardView2(
                        frontText: studyItems[currentIndex].front, // Variation (colored)
                        backText: studyItems[currentIndex].back,   // Word (gray) or example
                        germanWord: studyItems[currentIndex].germanWord, // For example mode: verb with prep
                        cardColor: mode.accentColor,
                        cardId: studyItems[currentIndex].wordId,
                        initialFlipped: cardFlipped, // true when reversed (shows Word first)
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
        VStack(spacing: 4) {
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
                
                // Title
                VStack(spacing: 2) {
                    Text(mode.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    // Card count
                    Text("\(studyItems.count) \(Localizable.string(Localizable.cards))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
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
        }
        .padding(.horizontal, 20)
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
        switch mode {
        case .synonyms, .explanation, .example:
            return "book.closed"
        case .translations:
            return "text.book.closed"
        }
    }
    
    var emptyStateTitle: String {
        if !hasSelectedWordsOrSections {
            return "Keine Wörter ausgewählt"
        }
        switch mode {
        case .synonyms:
            return "Keine Synonyme verfügbar"
        case .explanation:
            return "Keine Erklärungen verfügbar"
        case .example:
            return "Keine Beispiele verfügbar"
        case .translations:
            return "Keine Übersetzungen gefunden"
        }
    }
    
    var emptyStateMessage: String {
        if !hasSelectedWordsOrSections {
            return "Wähle die Wörter mit dem Häkchen aus"
        }
        switch mode {
        case .synonyms:
            return "Bitte füge Synonyme zu den Wörtern hinzu"
        case .explanation:
            return "Bitte füge Erklärungen zu den Wörtern hinzu"
        case .example:
            return "Bitte füge Beispiele zu den Wörtern hinzu"
        case .translations:
            return "Bitte füge Übersetzungen zu den Wörtern hinzu"
        }
    }
    
    private func handleWrong() {
        // Record spaced repetition result (quality 0-2 for wrong answers)
        let currentItem = studyItems[currentIndex]
        spacedRepetition.recordStudyResult(wordId: currentItem.wordId, mode: mode, quality: 0)
        
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
        spacedRepetition.recordStudyResult(wordId: currentItem.wordId, mode: mode, quality: 4)
        
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
        let prioritizedIds = spacedRepetition.getPrioritizedCards(wordIds: wordIds, mode: mode)
        
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
    let frontText: String
    let backText: String
    let germanWord: String? // For example mode: verb with preposition and case
    let cardColor: Color
    let cardId: String?
    let initialFlipped: Bool
    let onSwipeCorrect: (() -> Void)?
    let onSwipeWrong: (() -> Void)?
    
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var thresholdReached = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(
        frontText: String,
        backText: String,
        germanWord: String? = nil,
        cardColor: Color,
        cardId: String? = nil,
        initialFlipped: Bool = false,
        onSwipeCorrect: (() -> Void)? = nil,
        onSwipeWrong: (() -> Void)? = nil
    ) {
        self.frontText = frontText
        self.backText = backText
        self.germanWord = germanWord
        self.cardColor = cardColor
        self.cardId = cardId
        self.initialFlipped = initialFlipped
        self.onSwipeCorrect = onSwipeCorrect
        self.onSwipeWrong = onSwipeWrong
    }
    
    private let grayColor = Color(.systemGray5)
    private let swipeThreshold: CGFloat = 120
    private let rotationAmount: Double = 15
    
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
                Text(frontText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
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
                    
                    // Show German word below example for example mode
                    if let germanWord = germanWord {
                        Text(germanWord)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
            }
            .accessibilityLabel("Card back: \(backText)\(germanWord != nil ? ". German word: \(germanWord!)" : "")")
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
        StudyView(mode: .synonyms, dataService: DataService(), filterBySectionId: nil, studyAllMode: true)
    }
}

