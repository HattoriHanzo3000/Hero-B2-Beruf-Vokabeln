//
//  WordsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData
import UIKit

struct WordsListView: View {
    let sectionId: String
    /// When set (e.g. opening from global search), scroll this row to the **vertical center** of the list after layout.
    var scrollToWordIdOnAppear: String? = nil
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Query(sort: \WordProgress.wordId) private var wordProgressList: [WordProgress]

    private var progressByWordId: [String: WordProgress] {
        Dictionary(uniqueKeysWithValues: wordProgressList.map { ($0.wordId, $0) })
    }

    private func userTranslation(for wordId: String) -> String {
        progressByWordId[wordId]?.translation ?? ""
    }
    @State private var navigateToStudy = false
    @State private var navigateToSettings = false
    @State private var showShareSheet = false
    @State private var showPaywall = false
    @State private var focusedTranslationWordId: String?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()
    @StateObject private var keyboardMetrics = WordListKeyboardMetrics()
    @State private var deepLinkScrollTask: Task<Void, Never>?

    var words: [Word] {
        dataService.getWords(for: sectionId)
    }
    
    var headerInfo: (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)? {
        dataService.getLectionAndSection(for: sectionId)
    }
    
    var hasAnyWordFavorited: Bool {
        !words.isEmpty && words.contains { dataService.isFavorite(wordId: $0.id) }
    }
    
    var isVerbenSection: Bool {
        sectionId.hasPrefix("VERBEN_")
    }
    
    var isAdjektiveSection: Bool {
        sectionId.hasPrefix("ADJEKTIVE_")
    }
    
    // Determine which stack this belongs to and get appropriate styling
    var stackInfo: (color: Color, icon: String, title: String) {
        if sectionId == DataService.userMyWordsSectionId {
            return (Color("AppRed"), "text.book.closed.fill", Localizable.string(Localizable.myWords))
        }
        if isVerbenSection {
            return (Color("AppBlue"), "figure.run", Localizable.string(Localizable.verbsWithPrepositions))
        }
        if isAdjektiveSection {
            return (Color("AppPurple"), "paintbrush.fill", Localizable.string(Localizable.adjectivesWithPrepositions))
        }
        // For general words sections (default)
        return (Color("AppGreen"), "square.stack.3d.up.fill", Localizable.string(Localizable.generalWords))
    }
    
    // Get preposition title for verben and adjektive sections
    var prepositionTitle: String {
        if isVerbenSection || isAdjektiveSection {
            // Extract preposition from sectionId (e.g., "VERBEN_an" -> "an", "ADJEKTIVE_an" -> "an")
            let parts = sectionId.split(separator: "_")
            if parts.count > 1 {
                return String(parts[1])
            }
        }
        return ""
    }

    private var wordsListScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.wordsListScrollWordId(for: sectionId) },
            set: { listUIState.setWordsListScrollWordId($0, for: sectionId) }
        )
    }

    private var listTranslationGroup: DataService.FavoriteGroupType {
        dataService.getGroupType(for: sectionId)
    }

    private var listTranslationTextColor: Color {
        WordListTranslationTextStyle.color(for: listTranslationGroup, colorScheme: colorScheme)
    }

    /// Bottom scroll inset: idle list needs little padding (Üben is in the nav bar); grows while editing with keyboard.
    private var wordsListBottomScrollMargin: CGFloat {
        if focusedTranslationWordId != nil, keyboardMetrics.bottomOverlap > 1 {
            return max(120, keyboardMetrics.bottomOverlap * 0.42 + 56)
        }
        return 28
    }

    var body: some View {
        ZStack {
            stackInfo.color.opacity(0.08)
                .ignoresSafeArea()
            
            ScrollViewReader { proxy in
                    List {
                    // Header matching GeneralWordsView style (now scrollable)
                    if isVerbenSection || isAdjektiveSection {
                        SwiftUI.Section {
                            EmptyView()
                        } header: {
                            WordsListHeaderView(
                                stackColor: stackInfo.color,
                                stackIcon: stackInfo.icon,
                                lectionTitle: "",
                                sectionTitle: prepositionTitle,
                                lectionNumber: "",
                                sectionLetter: ""
                            )
                            .id("wl-header-\(sectionId)")
                        }
                    } else if let info = headerInfo {
                        SwiftUI.Section {
                            EmptyView()
                        } header: {
                            WordsListHeaderView(
                                stackColor: stackInfo.color,
                                stackIcon: stackInfo.icon,
                                lectionTitle: info.lectionTitle,
                                sectionTitle: info.sectionTitle,
                                lectionNumber: info.lectionNumber,
                                sectionLetter: info.sectionLetter
                            )
                            .id("wl-header-\(sectionId)")
                        }
                    }
                    
                    // Words list directly in scrollable area
                    ForEach(words) { word in
                        WordRow(
                            word: word,
                            isFavorite: dataService.isFavorite(wordId: word.id),
                            dataService: dataService,
                            translationTextColor: listTranslationTextColor,
                            focusedTranslationWordId: $focusedTranslationWordId,
                            onFavoriteToggle: {
                                if dataService.toggleFavorite(wordId: word.id) {
                                    HapticManager.shared.lightImpact()
                                } else {
                                    HapticManager.shared.heavyImpact()
                                    showPaywall = true
                                }
                            }
                        )
                        .id(word.id)
                        .listRowBackground(Color.clear)
                    }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.never)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, 8, for: .scrollContent)
                    .contentMargins(.bottom, wordsListBottomScrollMargin, for: .scrollContent)
                    .scrollPosition(id: wordsListScrollBinding, anchor: .center)
                    .accessibilityLabel("Words list")
                    .accessibilityHint("List of German words with translations, explanations, and synonyms")
                    .onChange(of: focusedTranslationWordId) { _, newValue in
                        syncTranslationKeyboardNavBridge()
                        guard let id = newValue else { return }
                        scrollFocusedTranslationRowToVisible(using: proxy, wordId: id, delays: [0.35, 0.6, 0.95])
                    }
                    .onChange(of: keyboardMetrics.bottomOverlap) { _, newOverlap in
                        guard newOverlap > 1, let id = focusedTranslationWordId else { return }
                        scrollFocusedTranslationRowToVisible(using: proxy, wordId: id, delays: [0.04, 0.26])
                    }
                    .onChange(of: words.count) { _, _ in
                        syncTranslationKeyboardNavBridge()
                    }
                    .onAppear {
                        centerListOnDeepLinkIfNeeded(using: proxy)
                    }
                    .onDisappear {
                        deepLinkScrollTask?.cancel()
                        deepLinkScrollTask = nil
                    }
            }
        }
        .hidesBottomBarWhenPushed(true)
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: sectionId, // From section view: only this section
                studyAllMode: true // Always study all words in section
            )
            .environmentObject(dataService)
        }
        .fullScreenCover(isPresented: $navigateToSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(dataService)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                FloatingPracticeButton(
                    title: Localizable.string(Localizable.practiceWithCards),
                    accent: stackInfo.color,
                    isEnabled: true,
                    compactForToolbar: true
                ) {
                    HapticManager.shared.mediumImpact()
                    navigateToStudy = true
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                WordListShareButton(showShareSheet: $showShareSheet, showPaywall: $showPaywall)
            }
        }
        .wordListPremiumShareSheets(
            showShareSheet: $showShareSheet,
            showPaywall: $showPaywall,
            shareText: { generateShareText() },
            pdfURL: { generatePDF() }
        )
        .environmentObject(keyboardNavBridge)
        .onAppear {
            keyboardNavBridge.attachHandlers(
                onPrevious: navigateToPreviousTranslationField,
                onNext: navigateToNextTranslationField,
                onDismiss: { focusedTranslationWordId = nil }
            )
            syncTranslationKeyboardNavBridge()
        }
    }

    /// After opening from search, scrolls the target row to the **center** with **one** animation after a short layout yield (avoids stacked scrolls fighting on device).
    private func centerListOnDeepLinkIfNeeded(using proxy: ScrollViewProxy) {
        let fromParam = scrollToWordIdOnAppear
        if let id = fromParam {
            listUIState.setWordsListScrollWordId(id, for: sectionId)
        }
        let wordId = fromParam ?? listUIState.wordsListScrollWordId(for: sectionId)
        guard let wordId,
              words.contains(where: { $0.id == wordId }) else { return }

        let deepLink = fromParam != nil
        let sid = sectionId
        let targetId = wordId
        let reduceMotion = accessibilityReduceMotion

        deepLinkScrollTask?.cancel()
        deepLinkScrollTask = Task { @MainActor in
            // One layout pass so `List` has measured cells; cheap (no extra data loading).
            try? await Task.sleep(nanoseconds: 72_000_000)
            guard !Task.isCancelled else { return }
            if reduceMotion {
                proxy.scrollTo(targetId, anchor: .center)
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(targetId, anchor: .center)
                }
            }
            if deepLink {
                try? await Task.sleep(nanoseconds: 520_000_000)
                guard !Task.isCancelled else { return }
                listUIState.setWordsListScrollWordId(nil, for: sid)
            }
        }
    }

    /// Scrolls the active word row into the visible area above the keyboard; uses fresh `keyboardMetrics` inside delayed work.
    private func scrollFocusedTranslationRowToVisible(using proxy: ScrollViewProxy, wordId: String, delays: [TimeInterval]) {
        let metrics = keyboardMetrics
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let overlap = metrics.bottomOverlap
                let anchor: UnitPoint
                if overlap > 50 {
                    let y = min(0.32, 0.1 + (overlap / 950))
                    anchor = UnitPoint(x: 0.5, y: y)
                } else {
                    anchor = UnitPoint(x: 0.5, y: 0.5)
                }
                withAnimation(.easeInOut(duration: 0.28)) {
                    proxy.scrollTo(wordId, anchor: anchor)
                }
            }
        }
    }

    private func syncTranslationKeyboardNavBridge() {
        guard let fid = focusedTranslationWordId,
              let idx = words.firstIndex(where: { $0.id == fid }) else {
            keyboardNavBridge.syncCanNavigate(canPrevious: false, canNext: false)
            return
        }
        keyboardNavBridge.syncCanNavigate(
            canPrevious: idx > 0,
            canNext: idx < words.count - 1
        )
    }

    private func navigateToPreviousTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = words.firstIndex(where: { $0.id == fid }),
              idx > 0 else { return }
        focusedTranslationWordId = words[idx - 1].id
    }

    private func navigateToNextTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = words.firstIndex(where: { $0.id == fid }),
              idx < words.count - 1 else { return }
        focusedTranslationWordId = words[idx + 1].id
    }

    private func generateShareText() -> String {
        var header = ""
        if let info = headerInfo {
            header = "\(info.lectionTitle) - \(info.sectionTitle)\n\n"
        } else if isVerbenSection || isAdjektiveSection {
            header = "\(prepositionTitle)\n\n"
        }
        return WordListShareManager.shareText(
            words: words,
            header: header,
            translationProvider: { userTranslation(for: $0.id) }
        )
    }
    
    private func generatePDF() -> URL {
        let lectionTitle: String
        let lectionNumber: String?
        let sectionTitle: String
        let sectionLetter: String?
        
        if let info = headerInfo {
            lectionTitle = info.lectionTitle
            lectionNumber = info.lectionNumber.isEmpty ? nil : info.lectionNumber
            sectionTitle = info.sectionTitle
            sectionLetter = info.sectionLetter.isEmpty ? nil : info.sectionLetter
        } else if isVerbenSection || isAdjektiveSection {
            lectionTitle = stackInfo.title
            lectionNumber = nil
            sectionTitle = prepositionTitle
            sectionLetter = nil
        } else {
            lectionTitle = stackInfo.title
            lectionNumber = nil
            sectionTitle = ""
            sectionLetter = nil
        }
        
        let wordData = WordListShareManager.wordDataForPDF(
            words: words,
            translationProvider: { userTranslation(for: $0.id) }
        )
        
        let pdfInfo = PDFGenerationService.PDFInfo(
            lectionTitle: lectionTitle,
            lectionNumber: lectionNumber,
            sectionTitle: sectionTitle,
            sectionLetter: sectionLetter,
            headerColor: stackInfo.color,
            words: wordData,
            fileName: "WordsList_\(sectionId)"
        )
        
        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }
}

struct WordRow: View {
    let word: Word
    let isFavorite: Bool
    @ObservedObject var dataService: DataService
    let translationTextColor: Color
    @Binding var focusedTranslationWordId: String?
    let onFavoriteToggle: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var localTranslation: String = ""

    @Query private var progressMatches: [WordProgress]

    init(
        word: Word,
        isFavorite: Bool,
        dataService: DataService,
        translationTextColor: Color,
        focusedTranslationWordId: Binding<String?>,
        onFavoriteToggle: @escaping () -> Void
    ) {
        self.word = word
        self.isFavorite = isFavorite
        self.dataService = dataService
        self.translationTextColor = translationTextColor
        self._focusedTranslationWordId = focusedTranslationWordId
        self.onFavoriteToggle = onFavoriteToggle
        let id = word.id
        _progressMatches = Query(filter: #Predicate<WordProgress> { $0.wordId == id })
    }

    private var savedTranslation: String {
        progressMatches.first?.translation ?? ""
    }

    private var trimmedTranslation: String {
        savedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func beginEditingTranslation() {
        localTranslation = savedTranslation
        focusedTranslationWordId = word.id
    }
    
    private func attributedText(label: String, value: String, labelFont: Font = .system(.caption, design: .rounded).weight(.semibold), valueFont: Font = .system(.caption, design: .rounded), labelColor: Color = .secondary, valueColor: Color = .primary) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        if let labelRange = fullText.range(of: label) {
            fullText[labelRange].font = labelFont
            fullText[labelRange].foregroundColor = labelColor
        }
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
            fullText[valueRange].foregroundColor = valueColor
        }
        return fullText
    }
    
    private var hasWordDetailLines: Bool {
        let hasErkl = word.explanation?.isEmpty == false
        let hasBeisp = word.example?.isEmpty == false
        let hasSyn = !(word.synonyms?.isEmpty ?? true)
        return hasErkl || hasBeisp || hasSyn
    }

    private static let starColumnWidth: CGFloat = 32

    private var germanLemma: some View {
        Text(word.german)
            .font(.system(.body, design: .default, weight: .regular))
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isStaticText)
    }

    private var isEditingTranslation: Bool {
        focusedTranslationWordId == word.id
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isFavorite ? Color("AppYellow") : .secondary)
                    .symbolEffect(.bounce, value: isFavorite)
                    .frame(width: Self.starColumnWidth)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityValue(isFavorite ? "Favorited" : "Not favorited")
            .accessibilityHint("Toggle favorite for \(word.german)")
            .accessibilityAddTraits(isFavorite ? .isSelected : [])

            VStack(alignment: .leading, spacing: 8) {
                // Keep `TranslationTextField`’s UIKit view alive while jumping prev/next so the keyboard and accessory bar don’t flicker.
                HStack(alignment: isEditingTranslation ? .firstTextBaseline : .top, spacing: 10) {
                    germanLemma
                    ZStack(alignment: .topTrailing) {
                        TranslationTextField(
                            text: $localTranslation,
                            wordId: word.id,
                            focusedWordId: $focusedTranslationWordId,
                            placeholder: Localizable.string(Localizable.translation)
                        )
                        .opacity(isEditingTranslation ? 1 : 0)
                        .allowsHitTesting(isEditingTranslation)
                        .accessibilityHidden(!isEditingTranslation)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .alignmentGuide(.firstTextBaseline) { _ in
                            isEditingTranslation
                                ? TranslationTextField.rowFirstBaselineFromTopForBodyStyle()
                                : 0
                        }

                        if !isEditingTranslation {
                            Group {
                                if trimmedTranslation.isEmpty {
                                    Button(action: beginEditingTranslation) {
                                        Image(systemName: "pencil.line")
                                            .font(.system(size: 20, weight: .regular))
                                            .foregroundStyle(.secondary)
                                            .frame(minWidth: 44, alignment: .topTrailing)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .accessibilityLabel(Localizable.string(Localizable.addTranslationToWord))
                                    .accessibilityHint("Opens the keyboard to type your translation")
                                } else {
                                    Button(action: beginEditingTranslation) {
                                        Text(trimmedTranslation)
                                            .font(.system(.subheadline, design: .default, weight: .medium))
                                            .foregroundColor(translationTextColor)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .accessibilityLabel("Translation: \(trimmedTranslation)")
                                    .accessibilityHint("Double tap to edit translation")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if hasWordDetailLines {
                    VStack(alignment: .leading, spacing: 6) {
                        if let explanation = word.explanation, !explanation.isEmpty {
                            Text(
                                attributedText(
                                    label: "erkl: ",
                                    value: explanation,
                                    labelFont: WordListRowDetailTextStyle.explanationLabelFont,
                                    valueFont: WordListRowDetailTextStyle.explanationValueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Explanation: \(explanation)")
                        }

                        if let example = word.example, !example.isEmpty {
                            Text(
                                attributedText(
                                    label: "beisp: ",
                                    value: example,
                                    labelFont: WordListRowDetailTextStyle.explanationLabelFont,
                                    valueFont: WordListRowDetailTextStyle.explanationValueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Example: \(example)")
                        }

                        if let synonyms = word.synonyms, !synonyms.isEmpty {
                            let synonymsText = synonyms.joined(separator: ", ")
                            Text(
                                attributedText(
                                    label: "syn: ",
                                    value: synonymsText,
                                    labelFont: WordListRowDetailTextStyle.labelFont,
                                    valueFont: WordListRowDetailTextStyle.valueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Synonyms: \(synonymsText)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                focusedTranslationWordId == word.id
                    ? "\(word.german). Editing translation"
                    : (trimmedTranslation.isEmpty
                        ? "\(word.german). \(Localizable.string(Localizable.addTranslationToWord))"
                        : "\(word.german). Translation: \(trimmedTranslation)")
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Word row for \(word.german)")
        .onAppear {
            localTranslation = savedTranslation
        }
        .onChange(of: savedTranslation) { _, newValue in
            guard focusedTranslationWordId != word.id else { return }
            localTranslation = newValue
        }
        .onChange(of: localTranslation) { _, newValue in
            WordProgress.upsertTranslation(wordId: word.id, text: newValue, in: modelContext)
        }
    }
}

// MARK: - Words List Header View
struct WordsListHeaderView: View {
    let stackColor: Color
    let stackIcon: String
    let lectionTitle: String
    let sectionTitle: String
    let lectionNumber: String
    let sectionLetter: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(stackColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.25), lineWidth: 0.6)
                    )
                Image(systemName: stackIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
            }

            // Lektion + Abschnitt (Allgemeine Wörter): softer than title2/title3 — preposition-only rows unchanged below
            VStack(alignment: .leading, spacing: 8) {
                if !lectionTitle.isEmpty && !sectionTitle.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            if !lectionNumber.isEmpty {
                                Text(lectionNumber)
                                    .font(.system(.title3, design: .default, weight: .regular))
                                    .foregroundColor(.primary)
                            }
                            Text(lectionTitle)
                                .font(.system(.title3, design: .default, weight: .regular))
                                .foregroundColor(.primary)
                        }

                        HStack(spacing: 8) {
                            if !sectionLetter.isEmpty {
                                Text(sectionLetter.uppercased())
                                    .font(.system(.headline, design: .default, weight: .light))
                                    .foregroundColor(.primary)
                            }
                            Text(sectionTitle)
                                .font(.system(.headline, design: .default, weight: .light))
                                .foregroundColor(.primary)
                        }
                    }
                } else if !sectionTitle.isEmpty {
                    Text(sectionTitle)
                        .font(.system(.title2, design: .default, weight: .regular))
                        .foregroundColor(.primary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    NavigationStack {
        WordsListView(sectionId: "1A")
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
    .modelContainer(container)
}
