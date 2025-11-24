//
//  VerbsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct VerbsView: View {
    @ObservedObject var dataService: DataService
    @State private var selectedButtonType: ToolbarButtonType = .translation
    @State private var navigateToStudy = false
    
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
        ZStack {
            Color("AppGreenLight")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                // Header with Word of the Day
                HeaderView(dataService: dataService)
                
                // Üben button group
                UbenButtonGroupVerben(
                    selectedButtonType: $selectedButtonType,
                    onButtonTap: { buttonType in
                        navigateToStudy = true
                    }
                )
                
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
                    
                    ForEach(verbenPrepositions, id: \.id) { preposition in
                        NavigationLink(destination: WordsListView(sectionId: preposition.id)
                            .environmentObject(dataService)) {
                            HStack(spacing: 12) {
                                // Checkmark button
                                Button(action: {
                                    HapticManager.shared.lightImpact()
                                    dataService.toggleSectionCompleted(sectionId: preposition.id)
                                }) {
                                    Image(systemName: dataService.isSectionCompleted(sectionId: preposition.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.body)
                                        .foregroundColor(dataService.isSectionCompleted(sectionId: preposition.id) ? Color("AppGreen") : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                // Preposition title
                                Text(preposition.title)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.leading, 8)
                        }
                        .listRowBackground(Color("AppGreenExtraLight"))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 12, for: .scrollContent)
                .contentMargins(.bottom, 12, for: .scrollContent)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                mode: StudyMode(from: selectedButtonType),
                dataService: dataService,
                filterBySectionId: nil, // Process all sections (including VERBEN sections)
                studyAllMode: dataService.isVerbenCompleted() // Study all if all verben are checked
            )
            .environmentObject(dataService)
        }
    }
}

#Preview {
    NavigationStack {
        VerbsView(dataService: DataService())
    }
}

