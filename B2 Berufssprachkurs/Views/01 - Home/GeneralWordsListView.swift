//
//  GeneralWordsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct GeneralWordsListView: View {
    @ObservedObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    private var generalWordsScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.generalWordsScrollRowId },
            set: { listUIState.setGeneralWordsScrollRowId($0) }
        )
    }

    private func isLectionLocked(_ lectionId: Int) -> Bool {
        !subscriptionManager.isPremiumActive
            && !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lectionId)
    }

    private func requestPaywallForLocked() {
        HapticManager.shared.heavyImpact()
        showPaywall = true
    }

    var body: some View {
        StackRootListShell {
            List {
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    ScrollableStackRootHeader(
                        accent: Color("AppGreen"),
                        icon: "square.stack.3d.up.fill",
                        title: Localizable.string(Localizable.generalWords)
                    )
                    .id("gw-stack-header")
                }

                // Check all button header
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    StackListSelectAllHeader(
                        isSelected: subscriptionManager.isPremiumActive
                            && dataService.areAllGeneralWordsCompletedForStudy(isPremium: true),
                        fontDesign: .default,
                        action: {
                            if subscriptionManager.isPremiumActive {
                                dataService.toggleAllLections()
                            } else {
                                requestPaywallForLocked()
                            }
                        }
                    )
                    .id("gw-select-all")
                }

                // Lections (only first 12)
                ForEach(Array(dataService.lections.prefix(12))) { lection in
                    SwiftUI.Section {
                        if listUIState.generalWordsExpandedLectionIds.contains(lection.id) {
                            ForEach(lection.sections) { section in
                                SectionRowView(
                                    section: section,
                                    lection: lection,
                                    dataService: dataService,
                                    isLocked: isLectionLocked(lection.id),
                                    onPaywall: requestPaywallForLocked
                                )
                                    .listRowBackground(Color.clear)
                                    .id("gw-section-\(section.id)")
                            }
                        }
                    } header: {
                        LectionHeaderView(
                            lection: lection,
                            isExpanded: listUIState.generalWordsExpandedLectionIds.contains(lection.id),
                            onToggle: {
                                listUIState.toggleGeneralWordsLectionExpanded(lection.id)
                            },
                            dataService: dataService,
                            isLocked: isLectionLocked(lection.id),
                            onPaywall: requestPaywallForLocked
                        )
                        .id("gw-lection-\(lection.id)")
                    }
                }
            }
            .stackRootListChrome(scrollPosition: generalWordsScrollBinding)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

struct LectionHeaderView: View {
    let lection: Lection
    let isExpanded: Bool
    let onToggle: () -> Void
    @ObservedObject var dataService: DataService
    /// When true, the lection checkmark opens the paywall; expand/collapse still works so users can browse subsections.
    var isLocked: Bool = false
    var onPaywall: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme

    /// 0 = none, 1 = partial (lighter fill), 2 = all sections done (darker fill).
    private var lectionCheckmarkTier: Int {
        if dataService.isEverySectionCompleted(in: lection) { return 2 }
        if dataService.isAnySectionCompleted(in: lection) { return 1 }
        return 0
    }

    private var lectionCheckmarkForeground: Color {
        switch lectionCheckmarkTier {
        case 2: return CompletionCheckmarkPalette.fullFill(colorScheme)
        case 1: return CompletionCheckmarkPalette.partialFill(colorScheme)
        default: return Color.secondary
        }
    }

    /// Sized like the list `NavigationLink` disclosure (footnote + semibold); a touch darker than `.secondary`.
    private var lectionDisclosureChevronColor: Color {
        switch colorScheme {
        case .dark:
            return Color.primary.opacity(0.52)
        case .light:
            fallthrough
        @unknown default:
            return Color.primary.opacity(0.46)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkmark button
            Button(action: {
                if isLocked {
                    onPaywall()
                } else {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.toggleLectionCompleted(lectionId: lection.id)
                    }
                }
            }) {
                Image(systemName: lectionCheckmarkTier == 0 ? "circle" : "checkmark.circle.fill")
                    .font(.system(.callout, design: .default).weight(.medium))
                    .foregroundColor(lectionCheckmarkForeground)
                    .symbolEffect(.bounce, value: lectionCheckmarkTier)
            }
            .buttonStyle(.plain)
            
            // Expand/collapse — always allowed so free users can unfold and see locked subsections.
            Button(action: {
                HapticManager.shared.selection()
                onToggle()
            }) {
                HStack {
                    Image(systemName: "\(lection.id).circle.fill")
                        .font(.system(.title2, design: .default).weight(.medium))
                        .foregroundColor(Color("AppGreen"))
                    
                    Text(lection.title)
                        .font(.system(.title3, design: .default))
                        .foregroundColor(.primary)
                    
                    if isLocked {
                        ProShieldBadge(
                            label: "PRO",
                            color: Color.primary.opacity(0.72),
                            showShimmer: false,
                            style: .compact
                        )
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(.footnote, design: .default).weight(.semibold))
                        .foregroundColor(lectionDisclosureChevronColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct SectionRowView: View {
    let section: Section
    let lection: Lection
    @ObservedObject var dataService: DataService
    var isLocked: Bool = false
    var onPaywall: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme

    private var subsectionCheckmarkFillColor: Color {
        guard dataService.isSectionCompleted(sectionId: section.id) else { return .secondary }
        return dataService.isEverySectionCompleted(in: lection)
            ? CompletionCheckmarkPalette.fullFill(colorScheme)
            : CompletionCheckmarkPalette.partialFill(colorScheme)
    }

    // Extract letter from section ID (e.g., "1A" -> "a")
    private var sectionLetter: String {
        let lastChar = section.id.last?.lowercased() ?? ""
        return lastChar
    }
    
    // Check if this is a VERBEN section (should not show letter indicator)
    private var isVerbenSection: Bool {
        section.id.hasPrefix("VERBEN_")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark button
            Button(action: {
                if isLocked {
                    onPaywall()
                } else {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.toggleSectionCompleted(sectionId: section.id)
                    }
                }
            }) {
                Image(systemName: dataService.isSectionCompleted(sectionId: section.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(.subheadline, design: .default).weight(.medium))
                    .foregroundColor(subsectionCheckmarkFillColor)
                    .symbolEffect(.bounce, value: dataService.isSectionCompleted(sectionId: section.id))
            }
            .buttonStyle(.plain)

            rowLabelContent
        }
        .padding(.leading, 16)
        .opacity(isLocked ? 0.65 : 1.0)
    }

    @ViewBuilder
    private var rowLabelContent: some View {
        let label = HStack(spacing: 12) {
            if !sectionLetter.isEmpty && !isVerbenSection {
                Text(sectionLetter.uppercased())
                    .font(.system(.body, design: .default))
                    .fontWeight(.medium)
                    .foregroundColor(Color("AppGreen"))
            }

            Text(section.title)
                .font(.system(.subheadline, design: .default))
                .foregroundColor(.primary)

            if isLocked {
                ProShieldBadge(
                    label: "PRO",
                    color: Color.primary.opacity(0.72),
                    showShimmer: false,
                    style: .compact
                )
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)

        if isLocked {
            Button(action: onPaywall) {
                label
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(destination: WordsListView(sectionId: section.id)
                .environmentObject(dataService)) {
                label
            }
        }
    }
}

#Preview {
    GeneralWordsListView(dataService: DataService())
        .environmentObject(LearningListsUIState.shared)
        .background(Color("AppGreenLight"))
}

