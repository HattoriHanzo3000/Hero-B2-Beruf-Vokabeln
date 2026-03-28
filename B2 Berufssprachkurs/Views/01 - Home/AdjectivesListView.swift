//
//  AdjectivesListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AdjectivesListView: View {
    @ObservedObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState

    private var adjectivesScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.adjectivesRootScrollRowId },
            set: { listUIState.setAdjectivesRootScrollRowId($0) }
        )
    }

    // Prepositions for Adjektive mit Präpositionen
    private let adjektivePrepositions: [Section] = [
        Section(id: "ADJEKTIVE_an", title: "an"),
        Section(id: "ADJEKTIVE_auf", title: "auf"),
        Section(id: "ADJEKTIVE_bei", title: "bei"),
        Section(id: "ADJEKTIVE_für", title: "für"),
        Section(id: "ADJEKTIVE_gegenüber", title: "gegenüber"),
        Section(id: "ADJEKTIVE_in", title: "in"),
        Section(id: "ADJEKTIVE_mit", title: "mit"),
        Section(id: "ADJEKTIVE_nach", title: "nach"),
        Section(id: "ADJEKTIVE_über", title: "über"),
        Section(id: "ADJEKTIVE_um", title: "um"),
        Section(id: "ADJEKTIVE_von", title: "von"),
        Section(id: "ADJEKTIVE_vor", title: "vor"),
        Section(id: "ADJEKTIVE_zu", title: "zu")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Prepositions list
            List {
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    ScrollableStackRootHeader(
                        accent: Color("AppPurple"),
                        icon: "paintbrush.fill",
                        title: Localizable.string(Localizable.adjectivesWithPrepositions)
                    )
                    .id("adjectives-stack-header")
                }

                // Select-all header + preposition rows in one section (tighter gap than two separate sections)
                SwiftUI.Section {
                    ForEach(Array(adjektivePrepositions.enumerated()), id: \.element.id) { index, preposition in
                        AdjektiveRowView(
                            preposition: preposition,
                            rowNumber: index + 1,
                            dataService: dataService
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        .id("adjectives-row-\(preposition.id)")
                    }
                } header: {
                    HStack {
                        Button(action: {
                            HapticManager.shared.mediumImpact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dataService.toggleAdjektiveCompleted()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: dataService.isAdjektiveCompleted() ? "checkmark.circle.fill" : "circle")
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundColor(dataService.isAdjektiveCompleted() ? Color.gray : .secondary)
                                    .symbolEffect(.bounce, value: dataService.isAdjektiveCompleted())

                                Text(dataService.isAdjektiveCompleted() ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, 0)
                    .id("adjectives-select-all")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins(.bottom, 90, for: .scrollContent)
            .scrollPosition(id: adjectivesScrollBinding, anchor: .center)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdjektiveRowView: View {
    let preposition: Section
    let rowNumber: Int
    @ObservedObject var dataService: DataService
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark button
            Button(action: {
                HapticManager.shared.lightImpact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dataService.toggleSectionCompleted(sectionId: preposition.id)
                }
            }) {
                Image(systemName: dataService.isSectionCompleted(sectionId: preposition.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(dataService.isSectionCompleted(sectionId: preposition.id) ? Color.gray : .secondary)
                    .symbolEffect(.bounce, value: dataService.isSectionCompleted(sectionId: preposition.id))
            }
            .buttonStyle(.plain)
            
            // NavigationLink to words list (styled like lection header with numbered circle)
            NavigationLink {
                WordsListView(sectionId: preposition.id)
                    .environmentObject(dataService)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "\(rowNumber).circle.fill")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .foregroundColor(Color("AppPurple"))
                        .accessibilityHidden(true)
                    
                    Text(preposition.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AdjectivesListView(dataService: DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}

