//
//  WordsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct WordsListView: View {
    let sectionId: String
    @EnvironmentObject var dataService: DataService
    @State private var translations: [String: String] = [:]
    @State private var selectedButtonType: ToolbarButtonType = .translation
    @State private var navigateToStudy = false
    @State private var navigateToSettings = false
    @FocusState private var focusedWordId: String?
    
    var words: [Word] {
        dataService.getWords(for: sectionId)
    }
    
    var headerInfo: (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)? {
        dataService.getLectionAndSection(for: sectionId)
    }
    
    var allWordsChecked: Bool {
        !words.isEmpty && words.allSatisfy { dataService.isWordChecked(wordId: $0.id, in: sectionId) }
    }
    
    var isVerbenSection: Bool {
        sectionId.hasPrefix("VERBEN_")
    }
    
    var body: some View {
        ZStack {
            Color("AppGreenLight")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                // Words header
                if let info = headerInfo {
                    WordsHeaderView(
                        lectionTitle: info.lectionTitle,
                        sectionTitle: info.sectionTitle,
                        lectionNumber: info.lectionNumber,
                        sectionLetter: info.sectionLetter
                    )
                }
                
                // Üben button group
                if isVerbenSection {
                    UbenButtonGroupVerben(
                        selectedButtonType: $selectedButtonType,
                        onButtonTap: { buttonType in
                            navigateToStudy = true
                        }
                    )
                } else {
                    UbenButtonGroup(
                        selectedButtonType: $selectedButtonType,
                        onButtonTap: { buttonType in
                            navigateToStudy = true
                        }
                    )
                }
                
                // Words list
                ScrollViewReader { proxy in
                    List {
                        // Check all button header
                        SwiftUI.Section {
                            EmptyView()
                        } header: {
                            HStack {
                                Button(action: {
                                    HapticManager.shared.mediumImpact()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dataService.toggleAllWords(in: sectionId)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: allWordsChecked ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(allWordsChecked ? Color("AppGreen") : .secondary)
                                            .symbolEffect(.bounce, value: allWordsChecked)
                                        
                                        Text(allWordsChecked ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.vertical, 0)
            }
                        
                        ForEach(words) { word in
                            WordRow(
                                word: word,
                                sectionId: sectionId,
                                isChecked: dataService.isWordChecked(wordId: word.id, in: sectionId),
                                translation: translations[word.id] ?? word.translation,
                                dataService: dataService,
                                focusedWordId: $focusedWordId,
                                onCheckToggle: {
                                    HapticManager.shared.lightImpact()
                                    dataService.toggleWordChecked(wordId: word.id, in: sectionId)
                                },
                                onTranslationChange: { newTranslation in
                                    translations[word.id] = newTranslation
                                    dataService.updateTranslation(
                                        for: word.id,
                                        in: sectionId,
                                        translation: newTranslation
                                    )
                                }
                            )
                            .id(word.id)
                            .listRowBackground(Color("AppGreenExtraLight"))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, 0, for: .scrollContent)
                    .contentMargins(.bottom, 12, for: .scrollContent)
                    .padding(.top, 12)
                    .accessibilityLabel("Words list")
                    .accessibilityHint("List of German words with translations, explanations, and synonyms")
                    .onChange(of: focusedWordId) { oldValue, newValue in
                        if let wordId = newValue {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(wordId, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                mode: StudyMode(from: selectedButtonType),
                dataService: dataService,
                filterBySectionId: sectionId, // From section view: only this section
                studyAllMode: allWordsChecked // Study all if all words are checked
            )
            .environmentObject(dataService)
        }
        .navigationDestination(isPresented: $navigateToSettings) {
            SettingsView()
                .environmentObject(dataService)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button(action: {
                    HapticManager.shared.lightImpact()
                    navigateToPreviousField()
                }) {
                    Image(systemName: "chevron.up")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! <= 0)
                .accessibilityLabel("Previous word")
                .accessibilityHint("Navigate to the previous word in the list")
                
                Button(action: {
                    HapticManager.shared.lightImpact()
                    navigateToNextField()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! >= words.count - 1)
                .accessibilityLabel("Next word")
                .accessibilityHint("Navigate to the next word in the list")
            }
        }
        .onAppear {
            // Initialize translations from dataService
            for word in words {
                if !word.translation.isEmpty {
                    translations[word.id] = word.translation
                }
            }
        }
    }
    
    private func getCurrentWordIndex() -> Int? {
        guard let focusedId = focusedWordId,
              let index = words.firstIndex(where: { $0.id == focusedId }) else {
            return nil
        }
        return index
    }
    
    private func navigateToPreviousField() {
        guard let currentIndex = getCurrentWordIndex(),
              currentIndex > 0 else { return }
        let previousWordId = words[currentIndex - 1].id
        focusedWordId = previousWordId
        // Scrolling is handled by onChange(of: focusedWordId)
    }
    
    private func navigateToNextField() {
        guard let currentIndex = getCurrentWordIndex(),
              currentIndex < words.count - 1 else { return }
        let nextWordId = words[currentIndex + 1].id
        focusedWordId = nextWordId
        // Scrolling is handled by onChange(of: focusedWordId)
    }
    
}

struct WordRow: View {
    let word: Word
    let sectionId: String
    let isChecked: Bool
    let translation: String
    @ObservedObject var dataService: DataService
    @FocusState.Binding var focusedWordId: String?
    let onCheckToggle: () -> Void
    let onTranslationChange: (String) -> Void
    
    @State private var localTranslation: String = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkmark on the left
            Button(action: onCheckToggle) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundColor(isChecked ? Color("AppGreen") : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isChecked ? "Uncheck word" : "Check word")
            .accessibilityValue(isChecked ? "Checked" : "Unchecked")
            .accessibilityHint("Toggle selection for \(word.german)")
            .accessibilityAddTraits(isChecked ? .isSelected : [])
            
            // German word with example sentence
            VStack(alignment: .leading, spacing: 4) {
                Text(word.german)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let example = word.example, !example.isEmpty {
                    Text(example)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("German word: \(word.german)\(word.example != nil && !word.example!.isEmpty ? ". Example: \(word.example!)" : "")")
            
            // Translation column on the right with explanation, synonyms, and translation
            VStack(alignment: .leading, spacing: 6) {
                // Row 1: Explanation
                if let explanation = word.explanation, !explanation.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Text("erkl.:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(explanation)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Explanation: \(explanation)")
                }
                
                // Row 2: Synonyms
                if let synonyms = word.synonyms, !synonyms.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Text("syn.:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(synonyms.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Synonyms: \(synonyms.joined(separator: ", "))")
                }
                
                // Row 3: Translation input field
                TextField("Übersetzung", text: $localTranslation)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                    )
                    .focused($focusedWordId, equals: word.id)
                    .accessibilityLabel("Translation for \(word.german)")
                    .accessibilityHint("Enter the translation for this German word")
                    .accessibilityValue(localTranslation.isEmpty ? "Empty" : localTranslation)
                    .onAppear {
                        localTranslation = translation
                    }
                    .onChange(of: localTranslation) { oldValue, newValue in
                        onTranslationChange(newValue)
                    }
            }
            .frame(width: 150, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.leading, -8)
        .padding(.trailing, -8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Word row for \(word.german)")
    }
}

#Preview {
    NavigationStack {
        WordsListView(sectionId: "1A")
            .environmentObject(DataService())
    }
}
