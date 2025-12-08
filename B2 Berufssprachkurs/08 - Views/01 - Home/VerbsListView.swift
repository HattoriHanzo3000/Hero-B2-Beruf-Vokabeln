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
        VStack(alignment: .leading, spacing: 0) {
            // Prepositions list
            List {
                // Select All as first row item
                HStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dataService.toggleVerbenCompleted()
                        }
                    }) {
                        Image(systemName: dataService.isVerbenCompleted() ? "checkmark.circle.fill" : "circle")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(dataService.isVerbenCompleted() ? Color.gray : .secondary)
                            .symbolEffect(.bounce, value: dataService.isVerbenCompleted())
                    }
                    .buttonStyle(.plain)
                    
                    Text(dataService.isVerbenCompleted() ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                // Prepositions as list rows
                ForEach(verbenPrepositions, id: \.id) { preposition in
                    VerbenRowView(
                        preposition: preposition,
                        dataService: dataService
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
            }
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                BannerAd()
                    .background(Color("AppBlue").opacity(0.08))
            }
            .scrollContentBackground(.hidden)
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
        VerbsListView(dataService: DataService())
    }
}

