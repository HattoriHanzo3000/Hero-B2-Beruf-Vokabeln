//
//  StudyView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

enum StudyMode {
    case synonyms
    case explanation
    case translations
}

struct StudyView: View {
    let mode: StudyMode
    @ObservedObject var dataService: DataService
    
    @State private var currentIndex = 0
    @State private var studyItems: [StudyItem] = []
    
    var cardColor: Color {
        switch mode {
        case .synonyms:
            return .orange
        case .explanation:
            return .green
        case .translations:
            return .cyan
        }
    }
    
    var navigationTitle: String {
        switch mode {
        case .synonyms:
            return "Mit Synonymen üben"
        case .explanation:
            return "Mit Erklärungen üben"
        case .translations:
            return "Mit Übersetzungen üben"
        }
    }
    
    private func loadStudyItems() {
        var items: [StudyItem] = []
        
        // Get all sections that have words
        for lection in dataService.lections {
            for section in lection.sections {
                let words = dataService.getWords(for: section.id)
                
                switch mode {
                case .synonyms:
                    // For synonyms: show all words that have synonyms
                    for word in words {
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
                    }
                case .explanation:
                    // For explanation: show all words that have explanations
                    for word in words {
                        if let explanation = word.explanation, !explanation.isEmpty {
                            items.append(StudyItem(
                                front: explanation,
                                back: word.german,
                                wordId: word.id,
                                sectionId: section.id
                            ))
                        }
                    }
                case .translations:
                    // For translations: only show words where translation was written
                    for word in words {
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
        }
        
        studyItems = items.shuffled()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                cardColor.opacity(0.15)
                    .ignoresSafeArea()
                
                if studyItems.isEmpty {
                    emptyStateView
                } else if currentIndex < studyItems.count {
                    VStack(spacing: 24) {
                        // Progress indicator
                        progressView
                        
                        // Flashcard
                        FlashCardView(
                            frontText: studyItems[currentIndex].front,
                            backText: studyItems[currentIndex].back,
                            cardColor: cardColor
                        )
                        .padding(.horizontal, 20)
                        
                        // Navigation buttons
                        HStack(spacing: 16) {
                            Button(action: previousCard) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(cardColor.opacity(0.3))
                                    )
                            }
                            .disabled(currentIndex == 0)
                            .opacity(currentIndex == 0 ? 0.5 : 1.0)
                            
                            Spacer()
                            
                            Text("\(currentIndex + 1) / \(studyItems.count)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: nextCard) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(cardColor)
                                    )
                            }
                            .disabled(currentIndex >= studyItems.count - 1)
                            .opacity(currentIndex >= studyItems.count - 1 ? 0.5 : 1.0)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadStudyItems()
            }
            .onChange(of: dataService.wordsBySection) { _, _ in
                loadStudyItems()
            }
        }
    }
    
    private var progressView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(cardColor)
                    .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(studyItems.count), height: 4)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)
    }
    
    private var emptyStateView: some View {
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
    
    private func nextCard() {
        if currentIndex < studyItems.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        }
    }
    
    private func previousCard() {
        if currentIndex > 0 {
            withAnimation {
                currentIndex -= 1
            }
        }
    }
}

struct StudyItem {
    let front: String
    let back: String
    let wordId: String
    let sectionId: String
}

#Preview {
    StudyView(mode: .synonyms, dataService: DataService())
}
