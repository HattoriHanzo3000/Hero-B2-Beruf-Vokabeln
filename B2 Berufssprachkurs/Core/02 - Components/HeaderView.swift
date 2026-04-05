//
//  HeaderView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData
import UIKit

private struct HeroProRowAccessibility: ViewModifier {
    let useCombinedLabel: Bool
    let combinedLabel: String

    func body(content: Content) -> some View {
        if useCombinedLabel {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(combinedLabel)
        } else {
            content
        }
    }
}

struct HeaderView: View {
    @ObservedObject var dataService: DataService
    @Query(sort: \WordProgress.wordId) private var wordProgressRecords: [WordProgress]
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    private let isPremiumPreviewOverride: Bool?
    /// When `true`, only greeting / mascot / word-of-the-day are shown (no pinned gradient shell). Use on Home with a full-screen background gradient.
    private let embedInScrollContent: Bool
    /// When set (e.g. from `HomeView`), the free-tier “start free trial” label opens the paywall.
    private let showPaywall: Binding<Bool>?
    @State private var wordOfTheDay: Word? = nil
    @State private var showMascotGif = false
    @State private var gifPlayToken: UUID = UUID()
    @State private var autoPlayTask: Task<Void, Never>? = nil
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24_hours"
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = ""
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let gifAnimationDuration: Double = 1.1
    private let autoPlayInterval: TimeInterval = 15.0 // Auto-play every 15 seconds
    
    init(
        dataService: DataService,
        isPremiumPreviewOverride: Bool? = nil,
        embedInScrollContent: Bool = false,
        showPaywall: Binding<Bool>? = nil
    ) {
        self.dataService = dataService
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        self.embedInScrollContent = embedInScrollContent
        self.showPaywall = showPaywall
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

    /// Header copy uses a fixed typographic scale (not Dynamic Type).
    private var headerDynamicTypeRange: ClosedRange<DynamicTypeSize> {
        .large ... .large
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

    /// Prefixed detail labels (localized): bold condensed — heavier than list rows so WOTD stays the focus.
    private var wotdDetailLabelFont: Font {
        .system(.subheadline, design: .default, weight: .bold).width(.condensed)
    }

    /// Detail line body: medium condensed.
    private var wotdDetailValueFont: Font {
        .system(.subheadline, design: .default, weight: .medium).width(.condensed)
    }

    private var proBadgeColor: Color {
        embedInScrollContent ? (colorScheme == .light ? .black : .white) : .white
    }

    /// Same typographic style as `ProShieldBadge` standard labels (caption2 expanded medium).
    private var heroProSupplementFont: Font {
        .system(.caption2, weight: .medium).width(.expanded)
    }

    private var isPremiumUser: Bool {
        isPremiumPreviewOverride ?? subscriptionManager.isPremiumActive
    }

    /// Avoid showing “Start free trial” until the first entitlement refresh; sandbox subscribers otherwise see a one-frame flash.
    private var showHeroFreeTrialCallout: Bool {
        subscriptionManager.hasCompletedInitialSubscriptionSync && !isPremiumUser
    }

    /// Fixed height for the encouragement text well (matches mascot for a stable top band).
    private var heroEncouragementBoxHeight: CGFloat { mascotSize }

    /// Scales the hero encouragement line with the width available beside the mascot (narrow phones ↔ wide phones / iPad).
    private func heroEncouragementScaledPointSize(containerWidth width: CGFloat) -> CGFloat {
        let reference: CGFloat = 235
        var size = 15 * min(max(width / reference, 0.85), 1.24)
        if horizontalSizeClass == .regular {
            size *= 1.05
        }
        return min(max(size, 13), 19)
    }

    /// Greeting, eagle mascot, and word-of-the-day copy (optionally wrapped in `homeHeroIslandBackground` when embedded on Home).
    private var greetingMascotAndWordSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        ProShieldBadge(
                            label: "PRO",
                            color: proBadgeColor,
                            showShimmer: true
                        )
                        if showHeroFreeTrialCallout {
                            if let showPaywall {
                                Button {
                                    HapticManager.shared.lightImpact()
                                    showPaywall.wrappedValue = true
                                } label: {
                                    Text(Localizable.string(Localizable.startFreeTrial))
                                        .font(heroProSupplementFont)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(Color("AppOrange"))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(Color.white, lineWidth: 0.6)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(Localizable.string(Localizable.startFreeTrial))
                                    .font(heroProSupplementFont)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color("AppOrange"))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(Color.white, lineWidth: 0.6)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }
                    .modifier(HeroProRowAccessibility(
                        useCombinedLabel: isPremiumUser || showPaywall == nil || !showHeroFreeTrialCallout,
                        combinedLabel: isPremiumUser
                            ? "PRO"
                            : (showHeroFreeTrialCallout ? "PRO, \(Localizable.string(Localizable.startFreeTrial))" : "PRO")
                    ))

                    GeometryReader { geo in
                        let fontSize = heroEncouragementScaledPointSize(containerWidth: geo.size.width)
                        Text(Localizable.string(Localizable.heroWordOfTheDayEncouragement))
                            .font(.system(size: fontSize, weight: .medium, design: .default).italic())
                            .foregroundColor(.white.opacity(0.92))
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.65)
                            .lineLimit(12)
                            .frame(
                                width: geo.size.width,
                                height: geo.size.height,
                                alignment: .topLeading
                            )
                            .id("hero_encouragement_\(languageManager.currentLanguage)")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: heroEncouragementBoxHeight, alignment: .topLeading)

                mascotView
            }

            VStack(alignment: .leading, spacing: 8) {
                if let word = wordOfTheDay {
                    (Text(Image(systemName: wordStackIcon(for: word)))
                        .font(.system(.body, design: .default, weight: .heavy))
                     + Text("  \(word.german)")
                        .font(.system(.title2, design: .default, weight: .bold))
                    )
                    .foregroundColor(wordOfTheDayAccentColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let explanation = word.explanation, !explanation.isEmpty {
                        Text(attributedText(
                            label: Localizable.string(Localizable.wordRowDetailLabelExplanation),
                            value: explanation,
                            labelFont: wotdDetailLabelFont,
                            valueFont: wotdDetailValueFont,
                            labelColor: .white.opacity(0.7),
                            valueColor: .white
                        ))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let example = word.example, !example.isEmpty {
                        Text(attributedText(
                            label: Localizable.string(Localizable.wordRowDetailLabelExample),
                            value: example,
                            labelFont: wotdDetailLabelFont,
                            valueFont: wotdDetailValueFont,
                            labelColor: .white.opacity(0.7),
                            valueColor: .white
                        ))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !displayedTranslation(for: word).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(attributedText(
                            label: Localizable.string(Localizable.wordRowDetailLabelTranslation),
                            value: displayedTranslation(for: word),
                            labelFont: wotdDetailLabelFont,
                            valueFont: wotdDetailValueFont,
                            labelColor: .white.opacity(0.7),
                            valueColor: .white
                        ))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let synonyms = word.synonyms, let firstSynonym = synonyms.first {
                        Text(attributedText(
                            label: Localizable.string(Localizable.wordRowDetailLabelSynonyms),
                            value: firstSynonym,
                            labelFont: wotdDetailLabelFont,
                            valueFont: wotdDetailValueFont,
                            labelColor: .white.opacity(0.7),
                            valueColor: .white
                        ))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(Localizable.string(Localizable.wordOfTheDay))
                        .font(.system(.title2, design: .default, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
    private let mascotSize: CGFloat = 100

    private var mascotView: some View {
        ZStack {
            Image(staticMascotAssetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: mascotSize, height: mascotSize)
                .opacity((showMascotGif && !reduceMotion) ? 0 : 1)
            
            AnimatedGIFView(
                gifName: gifMascotAssetName,
                contentMode: .scaleAspectFit,
                shouldAnimate: showMascotGif && !reduceMotion
            )
            .id(gifPlayToken)
            .frame(width: mascotSize, height: mascotSize)
            .opacity((showMascotGif && !reduceMotion) ? 1 : 0)
            .allowsHitTesting(false)
        }
        .frame(width: mascotSize, height: mascotSize)
        .scaleEffect(x: -1, y: 1)
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
            return "book.fill"
        }

        if sectionId == DataService.userMyWordsSectionId {
            return "person.fill"
        }
        if sectionId.hasPrefix("VERBEN_") {
            return "figure.run"
        } else if sectionId.hasPrefix("ADJEKTIVE_") {
            return "paintpalette.fill"
        } else {
            return "book.fill"
        }
    }
    
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    HeaderView(dataService: DataService())
        .background(LearningSurfaceColors.generalWords)
        .modelContainer(container)
}

