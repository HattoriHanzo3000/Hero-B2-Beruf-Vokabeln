//
//  StudyView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct StudyItem {
    let front: String  // Variation (synonym, explanation, or translation)
    let back: String   // Word (German word)
    let wordId: String
    let sectionId: String
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
    @Namespace private var cardNamespace
    
    init(mode: StudyMode, dataService: DataService, filterBySectionId: String? = nil, studyAllMode: Bool = false) {
        self.mode = mode
        self.dataService = dataService
        self.filterBySectionId = filterBySectionId
        self.studyAllMode = studyAllMode
    }
    
    private func loadStudyItems() {
        var items: [StudyItem] = []
        
        // Determine which sections to process
        var sectionsToProcess: [(section: Section, lection: Lection)] = []
        
        if let sectionId = filterBySectionId {
            // From section view: only process the specified section
            for lection in dataService.lections {
                if let section = lection.sections.first(where: { $0.id == sectionId }) {
                    sectionsToProcess.append((section: section, lection: lection))
                    break
                }
            }
        } else {
            // From home view: process all sections
            for lection in dataService.lections {
                for section in lection.sections {
                    sectionsToProcess.append((section: section, lection: lection))
                }
            }
        }
        
        // Process each section
        for (section, lection) in sectionsToProcess {
            // If not in study all mode and from home view, filter by checked sections/lections
            if !studyAllMode && filterBySectionId == nil {
                // From home view: only include checked sections or sections in checked lections
                let isSectionCompleted = dataService.isSectionCompleted(sectionId: section.id)
                let isLectionCompleted = dataService.isLectionCompleted(lectionId: lection.id)
                
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
            
            // Process words based on study mode
            for word in wordsToProcess {
                switch mode {
                case .synonyms:
                    // For synonyms: show all words that have synonyms
                    if !word.synonyms.isEmpty {
                        // Randomly pick a synonym or use the first one
                        let synonym = word.synonyms.randomElement() ?? word.synonyms.first ?? ""
                        items.append(StudyItem(
                            front: synonym,
                            back: word.german,
                            wordId: word.id,
                            sectionId: section.id
                        ))
                    }
                case .explanation:
                    // For explanation: show all words that have explanations
                    if let explanation = word.explanation, !explanation.isEmpty {
                        items.append(StudyItem(
                            front: explanation,
                            back: word.german,
                            wordId: word.id,
                            sectionId: section.id
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
                            sectionId: section.id
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
                emptyStateView
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
                        backText: studyItems[currentIndex].back,   // Word (gray)
                        cardColor: mode.accentColor,
                        cardId: studyItems[currentIndex].wordId,
                        initialFlipped: cardFlipped // true when reversed (shows Word first)
                    )
                    .id("card-\(currentIndex)")
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
                    .padding(.horizontal, 20)
                    
                    // Wrong and Correct buttons - directly under flashcard
                    HStack(spacing: 24) {
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            handleWrong()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(width: 64, height: 64)
                                .background(liquidGlassCircle)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            HapticManager.shared.mediumImpact()
                            handleCorrect()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.green)
                                .frame(width: 64, height: 64)
                                .background(liquidGlassCircle)
                        }
                        .buttonStyle(ScaleButtonStyle())
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
        HStack {
            // Back button with liquid glass style
            Button(action: {
                HapticManager.shared.lightImpact()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(liquidGlassCircle)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // Title
            Text(mode.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Reverse button with liquid glass style
            Button(action: {
                HapticManager.shared.lightImpact()
                reverseCard()
            }) {
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isReversed ? .green : .primary)
                    .frame(width: 44, height: 44)
                    .background(liquidGlassCircle)
            }
            .buttonStyle(ScaleButtonStyle())
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
    
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                // Back button with liquid glass style
                Button(action: {
                    HapticManager.shared.lightImpact()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(liquidGlassCircle)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                // Title
                Text(mode.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Empty space to balance the layout
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
            
            // Empty state content
            VStack(spacing: 20) {
                Image(systemName: emptyStateIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text(emptyStateTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    var emptyStateIcon: String {
        switch mode {
        case .synonyms, .explanation:
            return "book.closed"
        case .translations:
            return "text.book.closed"
        }
    }
    
    var emptyStateTitle: String {
        switch mode {
        case .synonyms:
            return "Keine Synonyme verfügbar"
        case .explanation:
            return "Keine Erklärungen verfügbar"
        case .translations:
            return "Keine Übersetzungen gefunden"
        }
    }
    
    var emptyStateMessage: String {
        switch mode {
        case .synonyms:
            return "Bitte füge Synonyme zu den Wörtern hinzu"
        case .explanation:
            return "Bitte füge Erklärungen zu den Wörtern hinzu"
        case .translations:
            return "Bitte füge Übersetzungen zu den Wörtern hinzu"
        }
    }
    
    private func handleWrong() {
        // Record spaced repetition result (quality 0-2 for wrong answers)
        let currentItem = studyItems[currentIndex]
        spacedRepetition.recordStudyResult(wordId: currentItem.wordId, mode: mode, quality: 0)
        
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
    let cardColor: Color
    let cardId: String?
    let initialFlipped: Bool
    @State private var isFlipped = false
    
    init(frontText: String, backText: String, cardColor: Color, cardId: String? = nil, initialFlipped: Bool = false) {
        self.frontText = frontText
        self.backText = backText
        self.cardColor = cardColor
        self.cardId = cardId
        self.initialFlipped = initialFlipped
    }
    
    private let grayColor = Color(.systemGray5)
    
    var body: some View {
        ZStack {
            frontCard
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            backCard
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.5)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: cardId) { _, _ in
            isFlipped = initialFlipped
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
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
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
                Text(backText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
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

