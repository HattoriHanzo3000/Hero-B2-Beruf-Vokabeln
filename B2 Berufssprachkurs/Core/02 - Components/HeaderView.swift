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
    init(dataService: DataService, isPremiumPreviewOverride: Bool? = nil) {
        self.dataService = dataService
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
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
        ZStack(alignment: .top) {
            // Background that extends to top edge - fully opaque in dark mode
            LinearGradient(
                colors: colorScheme == .dark ? [
                    // Fully opaque darker versions for night mode
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
                // Additional dark overlay in dark mode for deeper, fully opaque colors
                colorScheme == .dark ? Color.black.opacity(0.5) : Color.clear
            )
            .ignoresSafeArea(edges: .top)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 12, x: 0, y: 6)
            
            // Content that respects safe area
        VStack(alignment: .leading, spacing: 12) {
            // Premium shield (Hero-style): top-trailing row above greeting, home tab only.
            if shouldShowPremiumBadge {
                HStack {
                    Spacer(minLength: 0)
                    PremiumShieldBadge(
                        label: Localizable.string(Localizable.premium),
                        color: .white,
                        showShimmer: true
                    )
                }
            }

            // Greeting row above mascot and word of the day
            Text(dailyGreeting)
                .font(.system(.title2, design: .default, weight: .medium).italic())
                .foregroundColor(.white.opacity(0.9))
                .id("greeting_\(languageManager.currentLanguage)_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)")
            
        HStack(alignment: .top, spacing: 5) {
            // Mascot on the left top with animation
            mascotView
                .padding(.top, 4)
            
            // 5 rows of text content
            VStack(alignment: .leading, spacing: 8) {
                    // Row 1: Word of the day
                if let word = wordOfTheDay {
                    HStack(alignment: .center, spacing: 8) {
                        // Group icon
                        Image(systemName: wordStackIcon(for: word))
                            .foregroundColor(Color("AppYellow"))
                            .font(.system(.title2, design: .default, weight: .heavy))

                        Text(word.german)
                            .font(.system(.title2, design: .default, weight: .semibold))
                            .foregroundColor(Color("AppYellow"))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                        // Row 2: Explanation
                    if let explanation = word.explanation, !explanation.isEmpty {
                        Text(attributedText(
                            label: "erkl: ",
                            value: explanation,
                            labelFont: .system(.subheadline, design: .default, weight: .heavy).width(.condensed),
                            valueFont: .system(.subheadline, design: .default, weight: .bold).width(.condensed),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                        // Row 3: Synonym
                    if let synonyms = word.synonyms, let firstSynonym = synonyms.first {
                        Text(attributedText(
                            label: "syn: ",
                            value: firstSynonym,
                            labelFont: .system(.subheadline, design: .default, weight: .heavy).width(.condensed),
                            valueFont: .system(.subheadline, design: .default, weight: .bold).width(.condensed),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                        // Row 4: Translation
                    if !displayedTranslation(for: word).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(attributedText(
                            label: "übers: ",
                            value: displayedTranslation(for: word),
                            labelFont: .system(.subheadline, design: .default, weight: .heavy).width(.condensed),
                            valueFont: .system(.subheadline, design: .default, weight: .bold).width(.condensed),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                        // Row 5: Example (last row)
                    if let example = word.example, !example.isEmpty {
                        Text(attributedText(
                            label: "beisp: ",
                            value: example,
                            labelFont: .system(.subheadline, design: .default, weight: .heavy).width(.condensed),
                            valueFont: .system(.subheadline, design: .default, weight: .bold).width(.condensed),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    // Empty state
                    Text(Localizable.string(Localizable.wordOfTheDay))
                        .font(.system(.largeTitle, design: .default, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            }
        }
            .padding(.top)
            .padding(.bottom, 18)
            .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
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
    
    private func attributedText(label: String, value: String, labelFont: Font = .system(.subheadline, design: .default, weight: .bold).width(.condensed), valueFont: Font = .system(.subheadline, design: .default, weight: .bold).width(.condensed), labelColor: Color? = nil) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        if let labelRange = fullText.range(of: label) {
            // Use the labelFont directly (with bold weight)
            fullText[labelRange].font = labelFont
            // Apply label color if provided
            if let labelColor = labelColor {
                fullText[labelRange].foregroundColor = labelColor
            }
        }
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
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

