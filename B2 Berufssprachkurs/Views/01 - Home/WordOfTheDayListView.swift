//
//  WordOfTheDayListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct WordOfTheDayListView: View {
    @Binding var selectedSections: String
    @ObservedObject var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSectionIds: Set<String> = []
    @State private var showProFeatureAlert = false
    
    // Free mode (Word of the Day) allows all 5 sections from lection 1.
    private var freeSelectableSectionIds: Set<String> {
        [
            "1A",
            "1B",
            "1C",
            "1D",
            "1E"
        ]
    }
    
    private func isFreeSection(_ sectionId: String) -> Bool {
        freeSelectableSectionIds.contains(sectionId)
    }
    
    private func canSelectSection(_ sectionId: String) -> Bool {
        if subscriptionManager.isPremiumActive { return true }
        return isFreeSection(sectionId)
    }
    
    /// Card-header index in a circle. Fixed font size so badges stay on-grid when Dynamic Type is large (titles still scale).
    private enum LectionIndexBadge {
        static let circleSize: CGFloat = 34
        /// `Font.system(size:)` does not follow Dynamic Type.
        static let numberFont = Font.system(size: 22, weight: .semibold, design: .default)
        
        static func circle(numberText: String, fillColor: Color) -> some View {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: circleSize, height: circleSize)
                Text(numberText)
                    .font(numberFont)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }
    
    /// Same interaction as `GeneralWordsListView` / `SectionRowView`: spring + SF Symbol bounce.
    private static let selectionSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    private struct BouncingSelectionCheckmark: View {
        let isSelected: Bool
        /// Card headers (lection / stacks 13–14) use callout; inner rows use subheadline like general words subsections.
        var isHeaderRow: Bool = false
        /// Toolbar “select all” uses `checkmark.circle` when off; list rows use plain `circle`.
        var outlineIsCheckmarkCircle: Bool = false
        var toolbarStyled: Bool = false
        
        private var symbolName: String {
            if isSelected { return "checkmark.circle.fill" }
            return outlineIsCheckmarkCircle ? "checkmark.circle" : "circle"
        }
        
        var body: some View {
            Image(systemName: symbolName)
                .foregroundStyle(isSelected ? Color.secondary : Color.secondary)
                .modifier(CheckmarkFontModifier(toolbarStyled: toolbarStyled, isHeaderRow: isHeaderRow))
                .symbolEffect(.bounce, value: isSelected)
        }
        
        private struct CheckmarkFontModifier: ViewModifier {
            let toolbarStyled: Bool
            let isHeaderRow: Bool
            
            @ViewBuilder
            func body(content: Content) -> some View {
                if toolbarStyled {
                    content.navigationBarSymbolStyle()
                } else if isHeaderRow {
                    content.font(.system(.callout, design: .default).weight(.medium))
                } else {
                    content.font(.system(.subheadline, design: .default).weight(.medium))
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppGreenLight")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(dataService.lections) { lection in
                            SelectionCard {
                                // Header - tap to toggle whole lection
                                HStack(spacing: 12) {
                                    LectionIndexBadge.circle(
                                        numberText: "\(lection.id)",
                                        fillColor: Color("AppGreen")
                                    )
                                    
                                    Text(lection.title)
                                        .font(.title2.weight(.semibold)) // match VERBEN title
                                        .foregroundColor(.primary)

                                    if !subscriptionManager.isPremiumActive && lection.id != DataService.GeneralWordsFreeTier.unlockedLectionId {
                                        ProShieldBadge(
                                            label: "PRO",
                                            color: Color.primary.opacity(0.72),
                                            showShimmer: false,
                                            style: .compact
                                        )
                                    }
                                    
                                    Spacer()
                                    
                                    BouncingSelectionCheckmark(
                                        isSelected: isLectionFullySelected(lection: lection),
                                        isHeaderRow: true
                                    )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticManager.shared.lightImpact()
                                    if subscriptionManager.isPremiumActive
                                        || lection.id == DataService.GeneralWordsFreeTier.unlockedLectionId {
                                        withAnimation(Self.selectionSpring) {
                                            toggleLectionSelection(lection: lection)
                                        }
                                    } else {
                                        HapticManager.shared.heavyImpact()
                                        showProFeatureAlert = true
                                    }
                                }
                            } content: {
                                VStack(spacing: 8) {
                                    ForEach(lection.sections) { section in
                                        HStack(spacing: 12) {
                                            // Letter (no background)
                                            Text(getSectionLetter(sectionId: section.id))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.secondary)
                                            
                                            Text(section.title)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            
                                            // Pro badge for non-free sections (free tier)
                                            if !canSelectSection(section.id) {
                                                ProShieldBadge(
                                                    label: "PRO",
                                                    color: Color.primary.opacity(0.72),
                                                    showShimmer: false,
                                                    style: .compact
                                                )
                                            }
                                            
                                            Spacer()
                                            
                                            BouncingSelectionCheckmark(isSelected: selectedSectionIds.contains(section.id))
                                        }
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            HapticManager.shared.lightImpact()
                                            if selectedSectionIds.contains(section.id) {
                                                withAnimation(Self.selectionSpring) {
                                                    _ = selectedSectionIds.remove(section.id)
                                                }
                                            } else {
                                                if canSelectSection(section.id) {
                                                    withAnimation(Self.selectionSpring) {
                                                        _ = selectedSectionIds.insert(section.id)
                                                    }
                                                } else {
                                                    HapticManager.shared.heavyImpact()
                                                    showProFeatureAlert = true
                                                }
                                            }
                                        }
                                        .opacity(canSelectSection(section.id) ? 1.0 : 0.6)
                                        
                                        if section.id != lection.sections.last?.id {
                                            Divider()
                                                .overlay(Color.white.opacity(0.15))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Verbs with Prepositions (VERBEN) Card
                        SelectionCard {
                            // Header - tap to toggle all VERBEN sections
                            HStack(spacing: 12) {
                                LectionIndexBadge.circle(
                                    numberText: "13",
                                    fillColor: Color("AppBlue")
                                )
                                
                                Text(Localizable.string(Localizable.verbsWithPrepositions))
                                    .font(.title2.weight(.semibold)) // bigger title
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                BouncingSelectionCheckmark(isSelected: isVerbenFullySelected(), isHeaderRow: true)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.lightImpact()
                                withAnimation(Self.selectionSpring) {
                                    toggleAllVerbenSelection()
                                }
                            }
                        } content: {
                            VStack(spacing: 8) {
                                ForEach(Array(verbenPrepositions.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: 12) {
                                        Text(item.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        // Pro badge for non-free sections (free tier)
                                        if !canSelectSection(item.id) {
                                            ProShieldBadge(
                                                label: "PRO",
                                                color: Color.primary.opacity(0.72),
                                                showShimmer: false,
                                                style: .compact
                                            )
                                        }
                                        
                                        Spacer()
                                        
                                        BouncingSelectionCheckmark(isSelected: selectedSectionIds.contains(item.id))
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        HapticManager.shared.lightImpact()
                                        if selectedSectionIds.contains(item.id) {
                                            withAnimation(Self.selectionSpring) {
                                                _ = selectedSectionIds.remove(item.id)
                                            }
                                        } else {
                                            if canSelectSection(item.id) {
                                                withAnimation(Self.selectionSpring) {
                                                    _ = selectedSectionIds.insert(item.id)
                                                }
                                            } else {
                                                HapticManager.shared.heavyImpact()
                                                showProFeatureAlert = true
                                            }
                                        }
                                    }
                                    .opacity(canSelectSection(item.id) ? 1.0 : 0.6)
                                    
                                    if item.id != verbenPrepositions.last?.id {
                                        Divider()
                                            .overlay(Color.white.opacity(0.15))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Adjectives with Prepositions (ADJEKTIVE) Card
                        SelectionCard {
                            // Header - tap to toggle all ADJEKTIVE sections
                            HStack(spacing: 12) {
                                LectionIndexBadge.circle(
                                    numberText: "14",
                                    fillColor: Color("AppPurple")
                                )
                                
                                Text(Localizable.string(Localizable.adjectivesWithPrepositions))
                                    .font(.title2.weight(.semibold)) // bigger title
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                BouncingSelectionCheckmark(isSelected: isAdjektiveFullySelected(), isHeaderRow: true)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.lightImpact()
                                withAnimation(Self.selectionSpring) {
                                    toggleAllAdjektiveSelection()
                                }
                            }
                        } content: {
                            VStack(spacing: 8) {
                                ForEach(Array(adjektivePrepositions.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: 12) {
                                        Text(item.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        // Pro badge for non-free sections (free tier)
                                        if !canSelectSection(item.id) {
                                            ProShieldBadge(
                                                label: "PRO",
                                                color: Color.primary.opacity(0.72),
                                                showShimmer: false,
                                                style: .compact
                                            )
                                        }
                                        
                                        Spacer()
                                        
                                        BouncingSelectionCheckmark(isSelected: selectedSectionIds.contains(item.id))
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        HapticManager.shared.lightImpact()
                                        if selectedSectionIds.contains(item.id) {
                                            withAnimation(Self.selectionSpring) {
                                                _ = selectedSectionIds.remove(item.id)
                                            }
                                        } else {
                                            if canSelectSection(item.id) {
                                                withAnimation(Self.selectionSpring) {
                                                    _ = selectedSectionIds.insert(item.id)
                                                }
                                            } else {
                                                HapticManager.shared.heavyImpact()
                                                showProFeatureAlert = true
                                            }
                                        }
                                    }
                                    .opacity(canSelectSection(item.id) ? 1.0 : 0.6)
                                    
                                    if item.id != adjektivePrepositions.last?.id {
                                        Divider()
                                            .overlay(Color.white.opacity(0.15))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(Localizable.string(Localizable.wordOfTheDay))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        if isAllSelected() {
                            withAnimation(Self.selectionSpring) {
                                selectedSectionIds.removeAll()
                            }
                        } else {
                            withAnimation(Self.selectionSpring) {
                                selectAllSections()
                            }
                        }
                    } label: {
                        BouncingSelectionCheckmark(
                            isSelected: isAllSelected(),
                            outlineIsCheckmarkCircle: true,
                            toolbarStyled: true
                        )
                    }
                    .accessibilityLabel(Text(Localizable.string(Localizable.selectAll)))
                }
            }
        }
        .onAppear {
            loadSelection()
            if !subscriptionManager.isPremiumActive {
                sanitizeSelectionForCurrentTier(applyDefaultIfEmpty: true)
            }
        }
        .onChange(of: subscriptionManager.isPremiumActive) { _, _ in
            // On plan switch, keep only previously-selected free rows in WOTD.
            sanitizeSelectionForCurrentTier(applyDefaultIfEmpty: false)
        }
        .onDisappear {
            saveSelection()
        }
        .alert(
            Localizable.string(Localizable.proFeatureTitle),
            isPresented: $showProFeatureAlert
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.proFeatureOnlyMessage))
        }
    }
    
    // MARK: - Selection Card (matches Cockpit style)
    private struct SelectionCard<Header: View, Content: View>: View {
        @ViewBuilder let header: Header
        @ViewBuilder let content: Content
        
        init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
            self.header = header()
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                header
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color("AppGreenExtraLight"))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.35),
                                .white.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
    }
    
    private func loadSelection() {
        if selectedSections.isEmpty {
            // If empty, select only section 1A by default
            selectedSectionIds = Set(["1A"])
        } else {
            selectedSectionIds = Set(selectedSections.split(separator: ",").map { String($0) })
        }
    }
    
    private func saveSelection() {
        // Always save the actual selection list
        // Empty string means "default/not set" (which is 1A), so we never save as empty
        selectedSections = selectedSectionIds.sorted().joined(separator: ",")
    }

    private func sanitizeSelectionForCurrentTier(applyDefaultIfEmpty: Bool) {
        selectedSectionIds = selectedSectionIds.intersection(freeSelectableSectionIds)
        if applyDefaultIfEmpty && selectedSectionIds.isEmpty {
            selectedSectionIds = ["1A"]
        }
        selectedSections = selectedSectionIds.sorted().joined(separator: ",")
    }
    
    private func isLectionFullySelected(lection: Lection) -> Bool {
        let lectionSectionIds = Set(lection.sections.map { $0.id })
        return lectionSectionIds.isSubset(of: selectedSectionIds)
    }
    
    private func toggleLectionSelection(lection: Lection) {
        let lectionSectionIds = Set(lection.sections.map { $0.id })
        let isFullySelected = lectionSectionIds.isSubset(of: selectedSectionIds)
        
        if isFullySelected {
            // Deselect all sections in this lection
            selectedSectionIds.subtract(lectionSectionIds)
        } else {
            // Select all sections in this lection (only free ones if not premium)
            if subscriptionManager.isPremiumActive {
                selectedSectionIds.formUnion(lectionSectionIds)
            } else {
                let freeSectionIds = lectionSectionIds.filter { isFreeSection($0) }
                selectedSectionIds.formUnion(freeSectionIds)
            }
        }
    }
    
    // MARK: - VERBEN support
    private var verbenPrepositions: [(id: String, title: String)] {
        [
            ("VERBEN_an", "an"),
            ("VERBEN_auf", "auf"),
            ("VERBEN_aus", "aus"),
            ("VERBEN_bei", "bei"),
            ("VERBEN_bis", "bis"),
            ("VERBEN_durch", "durch"),
            ("VERBEN_für", "für"),
            ("VERBEN_gegen", "gegen"),
            ("VERBEN_in", "in"),
            ("VERBEN_mit", "mit"),
            ("VERBEN_nach", "nach"),
            ("VERBEN_über", "über"),
            ("VERBEN_um", "um"),
            ("VERBEN_unter", "unter"),
            ("VERBEN_von", "von"),
            ("VERBEN_vor", "vor"),
            ("VERBEN_zu", "zu")
        ]
    }
    
    private var verbenIdsSet: Set<String> {
        Set(verbenPrepositions.map { $0.id })
    }
    
    private func isVerbenFullySelected() -> Bool {
        if subscriptionManager.isPremiumActive {
            return verbenIdsSet.isSubset(of: selectedSectionIds)
        }
        return selectedSectionIds.contains(DataService.VerbenFreeTier.unlockedSectionId)
    }
    
    private func toggleAllVerbenSelection() {
        if subscriptionManager.isPremiumActive {
            if verbenIdsSet.isSubset(of: selectedSectionIds) {
                selectedSectionIds.subtract(verbenIdsSet)
            } else {
                selectedSectionIds.formUnion(verbenIdsSet)
            }
        } else {
            let an = DataService.VerbenFreeTier.unlockedSectionId
            if selectedSectionIds.contains(an) {
                selectedSectionIds.remove(an)
            } else {
                selectedSectionIds.insert(an)
            }
        }
    }
    
    // MARK: - ADJEKTIVE support
    private var adjektivePrepositions: [(id: String, title: String)] {
        [
            ("ADJEKTIVE_an", "an"),
            ("ADJEKTIVE_auf", "auf"),
            ("ADJEKTIVE_bei", "bei"),
            ("ADJEKTIVE_für", "für"),
            ("ADJEKTIVE_gegenüber", "gegenüber"),
            ("ADJEKTIVE_in", "in"),
            ("ADJEKTIVE_mit", "mit"),
            ("ADJEKTIVE_nach", "nach"),
            ("ADJEKTIVE_über", "über"),
            ("ADJEKTIVE_um", "um"),
            ("ADJEKTIVE_von", "von"),
            ("ADJEKTIVE_vor", "vor"),
            ("ADJEKTIVE_zu", "zu")
        ]
    }
    
    private var adjektiveIdsSet: Set<String> {
        Set(adjektivePrepositions.map { $0.id })
    }
    
    private func isAdjektiveFullySelected() -> Bool {
        if subscriptionManager.isPremiumActive {
            return adjektiveIdsSet.isSubset(of: selectedSectionIds)
        }
        return selectedSectionIds.contains(DataService.AdjektiveFreeTier.unlockedSectionId)
    }
    
    private func toggleAllAdjektiveSelection() {
        if subscriptionManager.isPremiumActive {
            if adjektiveIdsSet.isSubset(of: selectedSectionIds) {
                selectedSectionIds.subtract(adjektiveIdsSet)
            } else {
                selectedSectionIds.formUnion(adjektiveIdsSet)
            }
        } else {
            let an = DataService.AdjektiveFreeTier.unlockedSectionId
            if selectedSectionIds.contains(an) {
                selectedSectionIds.remove(an)
            } else {
                selectedSectionIds.insert(an)
            }
        }
    }
    
    private func selectAllSections() {
        if subscriptionManager.isPremiumActive {
            let allRegularSectionIds = Set(dataService.lections.flatMap { $0.sections.map { $0.id } })
            selectedSectionIds = allRegularSectionIds.union(verbenIdsSet).union(adjektiveIdsSet)
        } else {
            // Only select free sections
            selectedSectionIds = freeSelectableSectionIds
        }
    }
    
    private var allSectionIds: Set<String> {
        let regular = Set(dataService.lections.flatMap { $0.sections.map { $0.id } })
        return regular.union(verbenIdsSet).union(adjektiveIdsSet)
    }
    
    private func isAllSelected() -> Bool {
        if subscriptionManager.isPremiumActive {
            return allSectionIds.isSubset(of: selectedSectionIds)
        }
        return freeSelectableSectionIds.isSubset(of: selectedSectionIds)
    }
    
    private func getSectionLetter(sectionId: String) -> String {
        // Extract letter part from section ID (e.g., "1A" -> "A", "12B" -> "B")
        let letterPart = sectionId.replacingOccurrences(of: "^\\d+", with: "", options: .regularExpression)
        return letterPart.isEmpty ? sectionId : letterPart
    }
}

#Preview {
    WordOfTheDayListView(
        selectedSections: .constant(""),
        dataService: DataService()
    )
}
