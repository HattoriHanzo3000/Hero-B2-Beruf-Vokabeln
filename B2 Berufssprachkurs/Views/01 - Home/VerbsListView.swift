//
//  VerbsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct VerbsListView: View {
    @ObservedObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState

    private var verbsScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.verbsRootScrollRowId },
            set: { listUIState.verbsRootScrollRowId = $0 }
        )
    }

    // Prepositions for Verben mit Präpositionen
    private let verbenPrepositions: [Section] = [
        Section(id: "VERBEN_an", title: "an"),
        Section(id: "VERBEN_auf", title: "auf"),
        Section(id: "VERBEN_aus", title: "aus"),
        Section(id: "VERBEN_bei", title: "bei"),
        Section(id: "VERBEN_bis", title: "bis"),
        Section(id: "VERBEN_durch", title: "durch"),
        Section(id: "VERBEN_für", title: "für"),
        Section(id: "VERBEN_gegen", title: "gegen"),
        Section(id: "VERBEN_in", title: "in"),
        Section(id: "VERBEN_mit", title: "mit"),
        Section(id: "VERBEN_nach", title: "nach"),
        Section(id: "VERBEN_über", title: "über"),
        Section(id: "VERBEN_um", title: "um"),
        Section(id: "VERBEN_unter", title: "unter"),
        Section(id: "VERBEN_von", title: "von"),
        Section(id: "VERBEN_vor", title: "vor"),
        Section(id: "VERBEN_zu", title: "zu")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Prepositions list
            List {
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    ScrollableStackRootHeader(
                        accent: Color("AppBlue"),
                        icon: "figure.run",
                        title: Localizable.string(Localizable.verbsWithPrepositions)
                    )
                    .id("verbs-stack-header")
                }

                // Select-all header + preposition rows in one section (tighter gap than two separate sections)
                SwiftUI.Section {
                    ForEach(Array(verbenPrepositions.enumerated()), id: \.element.id) { index, preposition in
                        VerbenRowView(
                            preposition: preposition,
                            rowNumber: index + 1,
                            dataService: dataService
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        .id("verbs-row-\(preposition.id)")
                    }
                } header: {
                    HStack {
                        Button(action: {
                            HapticManager.shared.mediumImpact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dataService.toggleVerbenCompleted()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: dataService.isVerbenCompleted() ? "checkmark.circle.fill" : "circle")
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundColor(dataService.isVerbenCompleted() ? Color.gray : .secondary)
                                    .symbolEffect(.bounce, value: dataService.isVerbenCompleted())

                                Text(dataService.isVerbenCompleted() ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, 0)
                    .id("verbs-select-all")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins(.bottom, 90, for: .scrollContent)
            .scrollPosition(id: verbsScrollBinding, anchor: .center)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VerbenRowView: View {
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
                        .foregroundColor(Color("AppBlue"))
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
        VerbsListView(dataService: DataService())
            .environmentObject(LearningListsUIState.shared)
    }
}

