//
//  AdjectivesListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AdjectivesListView: View {
    @ObservedObject var dataService: DataService
    
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
                // Select All as first row item
                HStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dataService.toggleAdjektiveCompleted()
                        }
                    }) {
                        Image(systemName: dataService.isAdjektiveCompleted() ? "checkmark.circle.fill" : "circle")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(dataService.isAdjektiveCompleted() ? Color.gray : .secondary)
                            .symbolEffect(.bounce, value: dataService.isAdjektiveCompleted())
                    }
                    .buttonStyle(.plain)
                    
                    Text(dataService.isAdjektiveCompleted() ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                // Prepositions as list rows
                ForEach(adjektivePrepositions, id: \.id) { preposition in
                    AdjektiveRowView(
                        preposition: preposition,
                        dataService: dataService
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdjektiveRowView: View {
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
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(dataService.isSectionCompleted(sectionId: preposition.id) ? Color.gray : .secondary)
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
    }
}

