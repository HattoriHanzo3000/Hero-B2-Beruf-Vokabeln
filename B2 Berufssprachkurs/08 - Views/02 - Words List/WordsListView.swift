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
    @State private var selectedButtonType: ToolbarButtonType = .explanation
    @State private var navigateToStudy = false
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
                
                // Action buttons header
                ActionButtonsHeaderView(
                    onExplanationTap: {
                        HapticManager.shared.selection()
                        selectedButtonType = .explanation
                    },
                    onSynonymTap: {
                        HapticManager.shared.selection()
                        selectedButtonType = .synonym
                    },
                    onTranslationTap: {
                        HapticManager.shared.selection()
                        selectedButtonType = .translation
                    },
                    onCheckmarkTap: {
                        HapticManager.shared.mediumImpact()
                        dataService.toggleAllWords(in: sectionId)
                    },
                    onSettingsTap: {
                        HapticManager.shared.lightImpact()
                        // Handle settings tap
                    },
                    isCheckmarkSelected: allWordsChecked,
                    selectedButtonType: $selectedButtonType
                )
                
                // Words list
                ScrollViewReader { proxy in
                    List {
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
                    .contentMargins(.bottom, 70, for: .scrollContent)
                    .padding(.top, 12)
                    .onChange(of: focusedWordId) { oldValue, newValue in
                        if let wordId = newValue {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(wordId, anchor: .center)
                            }
                        }
                    }
                }
                
                Spacer()
                
                UbenButton(
                    action: {
                        HapticManager.shared.mediumImpact()
                        navigateToStudy = true
                    },
                    accentColor: selectedButtonType.color,
                    buttonText: selectedButtonType.buttonText
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
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
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! <= 0)
                
                Button(action: {
                    HapticManager.shared.lightImpact()
                    navigateToNextField()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! >= words.count - 1)
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
            
            // German word
            VStack(alignment: .leading, spacing: 4) {
                Text(word.german)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Translation input field on the right
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
                .frame(width: 150)
                .focused($focusedWordId, equals: word.id)
                .onAppear {
                    localTranslation = translation
                }
                .onChange(of: localTranslation) { oldValue, newValue in
                    onTranslationChange(newValue)
                }
        }
        .padding(.vertical, 10)
        .padding(.leading, -8)
        .padding(.trailing, -8)
    }
}

#Preview {
    NavigationStack {
        WordsListView(sectionId: "1A")
            .environmentObject(DataService())
    }
}
