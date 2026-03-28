//
//  HeaderView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData
import UIKit

struct HeaderView: View {
    @ObservedObject var dataService: DataService
    @Query(sort: \WordProgress.wordId) private var wordProgressRecords: [WordProgress]
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    private let isPremiumPreviewOverride: Bool?
    /// When `true`, only greeting / mascot / word-of-the-day are shown (no pinned gradient shell). Use on Home with a full-screen background gradient.
    private let embedInScrollContent: Bool
    /// When `true`, header typography ignores the user’s Dynamic Type setting (fixed at `.large`). Used for the pinned home header only.
    private let pinsDynamicTypeSize: Bool
    @State private var wordOfTheDay: Word? = nil
    @State private var showMascotGif = false
    @State private var gifPlayToken: UUID = UUID()
    @State private var autoPlayTask: Task<Void, Never>? = nil
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24_hours"
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = ""
    @AppStorage("hasShownFirstGreeting") private var hasShownFirstGreeting = false
    @State private var dailyGreeting: String
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let gifAnimationDuration: Double = 1.1
    private let autoPlayInterval: TimeInterval = 15.0 // Auto-play every 15 seconds
    
    // Initialize dailyGreeting based on UserDefaults to avoid flash
    init(dataService: DataService, isPremiumPreviewOverride: Bool? = nil, embedInScrollContent: Bool = false, pinsDynamicTypeSize: Bool = false) {
        self.dataService = dataService
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        self.embedInScrollContent = embedInScrollContent
        self.pinsDynamicTypeSize = pinsDynamicTypeSize
        // Read hasShownFirstGreeting directly from UserDefaults for initialization
        let hasShown = UserDefaults.standard.bool(forKey: "hasShownFirstGreeting")
        
        if !hasShown {
            // First greeting is always greeting 3
            _dailyGreeting = State(initialValue: Localizable.string(Localizable.greetingWordOfTheDay3))
        } else {
            // After first greeting, use random selection (consistent throughout the day)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dayHash = today.timeIntervalSince1970.hashValue
            
            let greetingKeys = [
                Localizable.greetingWordOfTheDay,
                Localizable.greetingWordOfTheDay1,
                Localizable.greetingWordOfTheDay2,
                Localizable.greetingWordOfTheDay3,
                Localizable.greetingWordOfTheDay4,
                Localizable.greetingWordOfTheDay5
            ]
            
            let index = abs(dayHash) % greetingKeys.count
            _dailyGreeting = State(initialValue: Localizable.string(greetingKeys[index]))
        }
    }
    
    var body: some View {
        Group {
            if embedInScrollContent {
                mainHeaderContent
            } else {
                ZStack(alignment: .top) {
                    pinnedHeaderGradientBackground
                    mainHeaderContent
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task {
            // Mark that first greeting has been shown after view appears
            // This ensures the greeting is set correctly before the view renders
            if !hasShownFirstGreeting {
                hasShownFirstGreeting = true
            }
        }
        .onAppear {
            updateWordOfTheDay()
            startAutoPlay()
        }
        .onChange(of: dataService.wordsBySection) { _, _ in
            updateWordOfTheDay()
        }
        .onChange(of: wordOfTheDayPeriodicity) { _, _ in
            updateWordOfTheDay()
        }
        .onChange(of: wordOfTheDaySelectedSections) { _, _ in
            updateWordOfTheDay()
        }
        .onDisappear {
            autoPlayTask?.cancel()
            autoPlayTask = nil
        }
        .dynamicTypeSize(headerDynamicTypeRange)
    }

    private var headerDynamicTypeRange: ClosedRange<DynamicTypeSize> {
        pinsDynamicTypeSize ? (.large ... .large) : (.xSmall ... .accessibility5)
    }

    /// Hero header background for the legacy pinned header layout (horizontal green → blue bar).
    private var pinnedHeaderGradientBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color("AppGreen").opacity(1.0),
                Color("AppBlue").opacity(1.0)
            ] : [
                Color("AppGreen"),
                Color("AppBlue")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .overlay(
            colorScheme == .dark ? Color.black.opacity(0.5) : Color.clear
        )
        .ignoresSafeArea(edges: .top)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 12, x: 0, y: 6)
    }

    private var mainHeaderContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if shouldShowPremiumBadge {
                HStack {
                    Spacer(minLength: 0)
                    PremiumShieldBadge(
                        label: Localizable.string(Localizable.premium),
                        color: embedInScrollContent ? (colorScheme == .light ? .black : .white) : .white,
                        showShimmer: true
                    )
                }
            }

            if embedInScrollContent {
                greetingMascotAndWordSection
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { homeHeroIslandBackground }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.22 : 0.45),
                                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.14), radius: 20, x: 0, y: 10)
            } else {
                greetingMascotAndWordSection
            }
        }
        .padding(.top)
        .padding(.bottom, embedInScrollContent ? 8 : 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Title, stack icon, and detail line *values*—deep green in light mode; brighter green in dark mode for contrast on the island.
    private var wordOfTheDayAccentColor: Color {
        if colorScheme == .dark {
            Color(red: 0.42, green: 0.82, blue: 0.58)
        } else {
            Color(red: 0.06, green: 0.38, blue: 0.26)
        }
    }

    /// Prefixed labels (`erkl:`, `beisp:`, etc.): bold condensed — heavier than list rows so WOTD stays the focus.
    private var wotdDetailLabelFont: Font {
        .system(.subheadline, design: .default, weight: .bold).width(.condensed)
    }

    /// Detail line body: medium condensed.
    private var wotdDetailValueFont: Font {
        .system(.subheadline, design: .default, weight: .medium).width(.condensed)
    }

    /// Greeting, eagle mascot, and word-of-the-day copy (optionally wrapped in `homeHeroIslandBackground` when embedded on Home).
    private var greetingMascotAndWordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(dailyGreeting)
                .font(.system(.title2, design: .default, weight: .medium).italic())
                .foregroundColor(.white.opacity(0.95))
                .id("greeting_\(languageManager.currentLanguage)_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)")

            HStack(alignment: .top, spacing: 5) {
                mascotView
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 8) {
                    if let word = wordOfTheDay {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: wordStackIcon(for: word))
                                .foregroundColor(wordOfTheDayAccentColor)
                                .font(.system(.title2, design: .default, weight: .heavy))

                            Text(word.german)
                                .font(.system(.title2, design: .default, weight: .semibold))
                                .foregroundColor(wordOfTheDayAccentColor)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let explanation = word.explanation, !explanation.isEmpty {
                            Text(attributedText(
                                label: "erkl: ",
                                value: explanation,
                                labelFont: wotdDetailLabelFont,
                                valueFont: wotdDetailValueFont,
                                labelColor: .white,
                                valueColor: .white
                            ))
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        if let synonyms = word.synonyms, let firstSynonym = synonyms.first {
                            Text(attributedText(
                                label: "syn: ",
                                value: firstSynonym,
                                labelFont: wotdDetailLabelFont,
                                valueFont: wotdDetailValueFont,
                                labelColor: .white,
                                valueColor: .white
                            ))
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        if !displayedTranslation(for: word).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(attributedText(
                                label: "übers: ",
                                value: displayedTranslation(for: word),
                                labelFont: wotdDetailLabelFont,
                                valueFont: wotdDetailValueFont,
                                labelColor: .white,
                                valueColor: .white
                            ))
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        if let example = word.example, !example.isEmpty {
                            Text(attributedText(
                                label: "beisp: ",
                                value: example,
                                labelFont: wotdDetailLabelFont,
                                valueFont: wotdDetailValueFont,
                                labelColor: .white,
                                valueColor: .white
                            ))
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        Text(Localizable.string(Localizable.wordOfTheDay))
                            .font(.system(.largeTitle, design: .default, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    /// Liquid Glass island: material blur tinted with the same green → blue palette as the legacy pinned header / home wash.
    private var homeHeroIslandBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(heroIslandGreenBlueTint)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(colorScheme == .dark ? 0.28 : 0.09))
        }
    }

    private var heroIslandGreenBlueTint: LinearGradient {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.62),
                    Color("AppBlue").opacity(0.55)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.52),
                    Color("AppBlue").opacity(0.46)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Mascot View
    private var shouldShowPremiumBadge: Bool {
        isPremiumPreviewOverride ?? subscriptionManager.isPremiumActive
    }

    private var mascotView: some View {
        ZStack {
            // Static image
            Image(staticMascotAssetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .opacity((showMascotGif && !reduceMotion) ? 0 : 1)
            
            // Animated GIF
            AnimatedGIFView(
                gifName: gifMascotAssetName,
                contentMode: .scaleAspectFit,
                shouldAnimate: showMascotGif && !reduceMotion
            )
            .id(gifPlayToken)
            .frame(width: 120, height: 120)
            .opacity((showMascotGif && !reduceMotion) ? 1 : 0)
            .allowsHitTesting(false)
        }
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.shared.lightImpact()
            playGifOnly()
        }
    }
    
    private var staticMascotAssetName: String {
        if colorScheme == .dark, UIImage(named: "MascotDark") != nil {
            return "MascotDark"
        }
        return "Mascot"
    }
    
    private var gifMascotAssetName: String {
        if colorScheme == .dark, gifExists(named: "MascotDark") {
            return "MascotDark"
        }
        return "Mascot"
    }
    
    private func gifExists(named name: String) -> Bool {
        let subdirectories: [String?] = [nil, "02 - Gifs", "GIFs", "Resources/02 - Gifs"]
        for subdirectory in subdirectories {
            if Bundle.main.url(forResource: name, withExtension: "gif", subdirectory: subdirectory) != nil {
                return true
            }
        }
        return false
    }
    
    private func playGifOnly() {
        guard !reduceMotion else { return }
        gifPlayToken = UUID()
        showMascotGif = true
        DispatchQueue.main.asyncAfter(deadline: .now() + gifAnimationDuration) {
            showMascotGif = false
        }
    }
    
    private func updateWordOfTheDay() {
        wordOfTheDay = dataService.getWordOfTheDay()
    }

    private func displayedTranslation(for word: Word) -> String {
        if let stored = wordProgressRecords.first(where: { $0.wordId == word.id })?.translation,
           !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stored
        }
        return word.translation
    }
    
    private func attributedText(
        label: String,
        value: String,
        labelFont: Font = .system(.subheadline, design: .default, weight: .bold).width(.condensed),
        valueFont: Font = .system(.subheadline, design: .default, weight: .bold).width(.condensed),
        labelColor: Color? = nil,
        valueColor: Color? = nil
    ) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        if let labelRange = fullText.range(of: label) {
            fullText[labelRange].font = labelFont
            if let labelColor {
                fullText[labelRange].foregroundColor = labelColor
            }
        }
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
            if let valueColor {
                fullText[valueRange].foregroundColor = valueColor
            }
        }
        return fullText
    }
    
    private func startAutoPlay() {
        autoPlayTask?.cancel()
        autoPlayTask = Task<Void, Never> { [reduceMotion] in
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(autoPlayInterval * 1_000_000_000))
                if Task.isCancelled { break }
                await MainActor.run {
                    playGifOnly()
                }
            }
        }
    }
    
    // MARK: - Word Stack Helpers
    private func findSectionId(for word: Word) -> String? {
        for (sectionId, words) in dataService.wordsBySection {
            if words.contains(where: { $0.id == word.id }) {
                return sectionId
            }
        }
        return nil
    }
    
    private func wordStackIcon(for word: Word) -> String {
        guard let sectionId = findSectionId(for: word) else {
            return "square.stack.3d.up.fill" // Default to general words
        }
        
        if sectionId.hasPrefix("VERBEN_") {
            return "figure.run"
        } else if sectionId.hasPrefix("ADJEKTIVE_") {
            return "paintbrush.fill"
        } else {
            return "square.stack.3d.up.fill"
        }
    }
    
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    HeaderView(dataService: DataService())
        .background(Color("AppGreenLight"))
        .modelContainer(container)
}

