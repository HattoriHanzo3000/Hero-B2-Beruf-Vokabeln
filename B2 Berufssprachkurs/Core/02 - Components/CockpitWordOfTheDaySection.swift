//
//  CockpitWordOfTheDaySection.swift
//  B2 Berufssprachkurs
//
//  Word of the Day card content: periodicity menu + source sections navigation.
//

import SwiftUI

private enum CockpitWotdMetrics {
    static let controlFontSize: CGFloat = 17
    static let controlChevronSize: CGFloat = 13
    static let controlMinHeight: CGFloat = 52
    static let controlHorizontalPadding: CGFloat = 18

    static let periodicityMenuOptions: [(tag: String, titleKey: String)] = [
        ("12_hours", Localizable.hours12),
        ("24_hours", Localizable.hours24)
    ]
}

struct CockpitWordOfTheDaySection: View {
    @Binding var selectedSectionsCSV: String
    @Binding var periodicity: String
    @ObservedObject var languageManager: LanguageManager
    var dataService: DataService

    private var periodicityBinding: Binding<String> {
        Binding(
            get: { periodicity },
            set: { periodicity = $0 }
        )
    }

    var body: some View {
        CockpitCard(
            titleIcon: "calendar",
            title: Localizable.string(Localizable.wordOfTheDay),
            subtitle: AnyView(Text(Localizable.string(Localizable.wordOfTheDayDescription)))
        ) {
            VStack(alignment: .leading, spacing: 14) {
                periodicityRow
                sourceSectionsLink
            }
            .dynamicTypeSize(.large ... .large)
            .padding(.top, 2)
        }
        .padding(.horizontal)
    }

    private var periodicityRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: CockpitWotdMetrics.controlFontSize, weight: .regular, design: .default))
                .foregroundStyle(.white)

            Text(Localizable.string(Localizable.periodicity))
                .font(.system(size: CockpitWotdMetrics.controlFontSize, weight: .medium, design: .default))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Menu {
                ForEach(CockpitWotdMetrics.periodicityMenuOptions, id: \.tag) { option in
                    Button {
                        periodicityBinding.wrappedValue = option.tag
                        HapticManager.shared.selection()
                    } label: {
                        HStack {
                            Text(Localizable.string(option.titleKey))
                                .font(AppFont.fixedExpanded(size: CockpitWotdMetrics.controlFontSize))
                            Spacer()
                            if periodicity == option.tag {
                                Image(systemName: "checkmark")
                                    .font(.system(size: CockpitWotdMetrics.controlFontSize, weight: .regular, design: .default))
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(
                        periodicity == "12_hours"
                            ? Localizable.string(Localizable.hours12Short)
                            : Localizable.string(Localizable.hours24Short)
                    )
                    .font(AppFont.fixedExpanded(size: CockpitWotdMetrics.controlFontSize))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    Image(systemName: "chevron.down")
                        .font(.system(size: CockpitWotdMetrics.controlChevronSize, weight: .regular, design: .default))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .menuActionDismissBehavior(.automatic)
            .id("wotd_periodicity_\(languageManager.currentLanguage)")
        }
        .frame(maxWidth: .infinity, minHeight: CockpitWotdMetrics.controlMinHeight, alignment: .center)
        .padding(.horizontal, CockpitWotdMetrics.controlHorizontalPadding)
        .background(WotdLiquidGlassCapsuleBackground())
    }

    private var sourceSectionsLink: some View {
        NavigationLink {
            WordOfTheDayListView(
                selectedSections: $selectedSectionsCSV,
                dataService: dataService
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checklist")
                    .font(.system(size: CockpitWotdMetrics.controlFontSize, weight: .regular, design: .default))
                    .foregroundStyle(.white)

                Text(Localizable.string(Localizable.sourceSections))
                    .font(.system(size: CockpitWotdMetrics.controlFontSize, weight: .medium, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 6) {
                    Text("\(WordOfTheDaySelectionPolicy.selectedSectionCount(csv: selectedSectionsCSV))")
                        .font(AppFont.fixedExpanded(size: CockpitWotdMetrics.controlFontSize))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Image(systemName: "chevron.right")
                        .font(.system(size: CockpitWotdMetrics.controlChevronSize, weight: .regular, design: .default))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, minHeight: CockpitWotdMetrics.controlMinHeight, alignment: .center)
            .padding(.horizontal, CockpitWotdMetrics.controlHorizontalPadding)
            .background(WotdLiquidGlassCapsuleBackground())
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.shared.lightImpact()
            }
        )
        .accessibilityLabel(
            "\(Localizable.string(Localizable.sourceSections)), \(String(format: Localizable.string(Localizable.selectedSections), WordOfTheDaySelectionPolicy.selectedSectionCount(csv: selectedSectionsCSV)))"
        )
    }
}
