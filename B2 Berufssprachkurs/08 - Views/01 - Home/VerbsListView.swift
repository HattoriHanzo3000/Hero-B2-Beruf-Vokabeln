//
//  VerbsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct VerbsListView: View {
    @ObservedObject var dataService: DataService
    
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
        VStack(alignment: .leading, spacing: 8) {
            // Prepositions list
            List {
                // Check all button header
                SwiftUI.Section {
                    EmptyView()
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
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(dataService.isVerbenCompleted() ? Color("AppGreen") : .secondary)
                                    .symbolEffect(.bounce, value: dataService.isVerbenCompleted())
                                
                                Text(dataService.isVerbenCompleted() ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.vertical, 0)
                }
                
                // Prepositions as list rows
                ForEach(verbenPrepositions, id: \.id) { preposition in
                    VerbenRowView(
                        preposition: preposition,
                        dataService: dataService
                    )
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 12, for: .scrollContent)
            .contentMargins(.bottom, 12, for: .scrollContent)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VerbenRowView: View {
    let preposition: Section
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
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(dataService.isSectionCompleted(sectionId: preposition.id) ? Color("AppGreen") : .secondary)
                    .symbolEffect(.bounce, value: dataService.isSectionCompleted(sectionId: preposition.id))
            }
            .buttonStyle(.plain)
            
            // NavigationLink to words list (styled like lection header)
            NavigationLink {
                WordsListView(sectionId: preposition.id)
                    .environmentObject(dataService)
            } label: {
                HStack {
                    Text(preposition.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        VerbsListView(dataService: DataService())
    }
}

