//
//  SectionSelectionView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct SectionSelectionView: View {
    @Binding var selectedSections: String
    @ObservedObject var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSectionIds: Set<String> = []
    @State private var showPaywall = false
    
    // Free sections: 1A, 1B, 1C, 1D, 1E
    private let freeSections: Set<String> = ["1A", "1B", "1C", "1D", "1E"]
    
    private func isFreeSection(_ sectionId: String) -> Bool {
        freeSections.contains(sectionId)
    }
    
    private func canSelectSection(_ sectionId: String) -> Bool {
        subscriptionManager.isPremiumActive || isFreeSection(sectionId)
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
                                    ZStack {
                                        Circle()
                                            .fill(Color("AppGreen"))
                                            .frame(width: 34, height: 34)
                                        Text("\(lection.id)")
                                            .font(.title2.weight(.semibold)) // match title font
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(lection.title)
                                        .font(.title2.weight(.semibold)) // match VERBEN title
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: isLectionFullySelected(lection: lection) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isLectionFullySelected(lection: lection) ? .primary : .secondary)
                                        .fontWeight(.semibold)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticManager.shared.lightImpact()
                                    // Check if all sections in lection are free or user has premium
                                    let allFree = lection.sections.allSatisfy { isFreeSection($0.id) }
                                    if subscriptionManager.isPremiumActive || allFree {
                                        toggleLectionSelection(lection: lection)
                                    } else {
                                        HapticManager.shared.heavyImpact()
                                        showPaywall = true
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
                                            
                                            // Premium badge for non-free sections
                                            if !canSelectSection(section.id) {
                                                Image(systemName: "crown.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: selectedSectionIds.contains(section.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedSectionIds.contains(section.id) ? .primary : .secondary)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            HapticManager.shared.lightImpact()
                                            if selectedSectionIds.contains(section.id) {
                                                selectedSectionIds.remove(section.id)
                                            } else {
                                                if canSelectSection(section.id) {
                                                    selectedSectionIds.insert(section.id)
                                                } else {
                                                    HapticManager.shared.heavyImpact()
                                                    showPaywall = true
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
                                ZStack {
                                    Circle()
                                        .fill(Color("AppGreen"))
                                        .frame(width: 34, height: 34)
                                    Text("13")
                                        .font(.title2.weight(.semibold)) // same as title
                                        .foregroundColor(.white)
                                }
                                
                                Text(Localizable.string(Localizable.verbsWithPrepositions))
                                    .font(.title2.weight(.semibold)) // bigger title
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: isVerbenFullySelected() ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isVerbenFullySelected() ? .primary : .secondary)
                                    .fontWeight(.semibold)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.lightImpact()
                                if subscriptionManager.isPremiumActive {
                                    toggleAllVerbenSelection()
                                } else {
                                    HapticManager.shared.heavyImpact()
                                    showPaywall = true
                                }
                            }
                        } content: {
                            VStack(spacing: 8) {
                                ForEach(Array(verbenPrepositions.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: 12) {
                                        Text(item.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        // Premium badge for non-free sections
                                        if !canSelectSection(item.id) {
                                            Image(systemName: "crown.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedSectionIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedSectionIds.contains(item.id) ? .primary : .secondary)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        HapticManager.shared.lightImpact()
                                        if selectedSectionIds.contains(item.id) {
                                            selectedSectionIds.remove(item.id)
                                        } else {
                                            if canSelectSection(item.id) {
                                                selectedSectionIds.insert(item.id)
                                            } else {
                                                HapticManager.shared.heavyImpact()
                                                showPaywall = true
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
                                ZStack {
                                    Circle()
                                        .fill(Color("AppGreen"))
                                        .frame(width: 34, height: 34)
                                    Text("14")
                                        .font(.title2.weight(.semibold)) // same as title
                                        .foregroundColor(.white)
                                }
                                
                                Text(Localizable.string(Localizable.adjectivesWithPrepositions))
                                    .font(.title2.weight(.semibold)) // bigger title
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: isAdjektiveFullySelected() ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isAdjektiveFullySelected() ? .primary : .secondary)
                                    .fontWeight(.semibold)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.lightImpact()
                                if subscriptionManager.isPremiumActive {
                                    toggleAllAdjektiveSelection()
                                } else {
                                    HapticManager.shared.heavyImpact()
                                    showPaywall = true
                                }
                            }
                        } content: {
                            VStack(spacing: 8) {
                                ForEach(Array(adjektivePrepositions.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: 12) {
                                        Text(item.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        // Premium badge for non-free sections
                                        if !canSelectSection(item.id) {
                                            Image(systemName: "crown.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedSectionIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedSectionIds.contains(item.id) ? .primary : .secondary)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        HapticManager.shared.lightImpact()
                                        if selectedSectionIds.contains(item.id) {
                                            selectedSectionIds.remove(item.id)
                                        } else {
                                            if canSelectSection(item.id) {
                                                selectedSectionIds.insert(item.id)
                                            } else {
                                                HapticManager.shared.heavyImpact()
                                                showPaywall = true
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
                    .padding(.bottom, 60) // Space for fixed banner ad
                }
            }
            .safeAreaInset(edge: .bottom) {
                BannerAd()
                    .background(Color("AppGreenLight"))
            }
            .navigationTitle(Localizable.string(Localizable.wordOfTheDay))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        if isAllSelected() {
                            selectedSectionIds.removeAll()
                        } else {
                            if subscriptionManager.isPremiumActive {
                                selectAllSections()
                            } else {
                                HapticManager.shared.heavyImpact()
                                showPaywall = true
                            }
                        }
                    } label: {
                        Image(systemName: isAllSelected() ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isAllSelected() ? .primary : .secondary)
                    }
                    .accessibilityLabel(Text(Localizable.string(Localizable.selectAll)))
                }
            }
        }
        .onAppear {
            loadSelection()
        }
        .onDisappear {
            saveSelection()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
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
        selectedSections = selectedSectionIds.joined(separator: ",")
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
        verbenIdsSet.isSubset(of: selectedSectionIds)
    }
    
    private func toggleAllVerbenSelection() {
        if isVerbenFullySelected() {
            selectedSectionIds.subtract(verbenIdsSet)
        } else {
            selectedSectionIds.formUnion(verbenIdsSet)
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
        adjektiveIdsSet.isSubset(of: selectedSectionIds)
    }
    
    private func toggleAllAdjektiveSelection() {
        if isAdjektiveFullySelected() {
            selectedSectionIds.subtract(adjektiveIdsSet)
        } else {
            selectedSectionIds.formUnion(adjektiveIdsSet)
        }
    }
    
    private func selectAllSections() {
        if subscriptionManager.isPremiumActive {
            let allRegularSectionIds = Set(dataService.lections.flatMap { $0.sections.map { $0.id } })
            selectedSectionIds = allRegularSectionIds.union(verbenIdsSet).union(adjektiveIdsSet)
        } else {
            // Only select free sections
            selectedSectionIds = freeSections
        }
    }
    
    private var allSectionIds: Set<String> {
        let regular = Set(dataService.lections.flatMap { $0.sections.map { $0.id } })
        return regular.union(verbenIdsSet).union(adjektiveIdsSet)
    }
    
    private func isAllSelected() -> Bool {
        allSectionIds.isSubset(of: selectedSectionIds)
    }
    
    private func getSectionLetter(sectionId: String) -> String {
        // Extract letter part from section ID (e.g., "1A" -> "A", "12B" -> "B")
        let letterPart = sectionId.replacingOccurrences(of: "^\\d+", with: "", options: .regularExpression)
        return letterPart.isEmpty ? sectionId : letterPart
    }
}

#Preview {
    SectionSelectionView(
        selectedSections: .constant(""),
        dataService: DataService()
    )
}

