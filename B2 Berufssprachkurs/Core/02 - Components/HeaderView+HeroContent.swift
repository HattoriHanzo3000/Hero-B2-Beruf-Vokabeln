//
//  HeaderView+HeroContent.swift
//  B2 Berufssprachkurs
//

import SwiftUI

extension HeaderView {
    /// Greeting, eagle mascot, and word-of-the-day copy (optionally wrapped in `homeHeroIslandBackground` when embedded on Home).
    var greetingMascotAndWordSection: some View {
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
                            HeroFreeTrialChip(
                                font: heroProSupplementFont,
                                onTap: showPaywall.map { binding in
                                    { binding.wrappedValue = true }
                                }
                            )
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: showHeroFreeTrialCallout)
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

                MascotView()
            }

            VStack(alignment: .leading, spacing: 8) {
                if let word = wordOfTheDay {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Image(systemName: wordStackIcon(for: word))
                            .font(wotdStackIconFont)
                            .wotdHeadlineIconBaselineAlignment()

                        Text(word.german)
                            .font(.system(.title2, design: .default, weight: .bold))

                        if let sectionLabel = wordOfTheDayGeneralSectionBadgeCaption(for: word) {
                            Text(sectionLabel)
                                .font(wotdSectionBadgeFont)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(wordOfTheDayAccentColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(
                                            wordOfTheDayAccentColor,
                                            lineWidth: wotdSectionBadgeStrokeWidth
                                        )
                                )
                                .accessibilityHidden(true)
                        }
                    }
                    .foregroundColor(wordOfTheDayAccentColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(wordOfTheDayHeadlineAccessibilityLabel(for: word))

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

                    if let synonyms = word.synonyms, let firstSynonym = synonyms.first, !firstSynonym.isEmpty {
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
}
