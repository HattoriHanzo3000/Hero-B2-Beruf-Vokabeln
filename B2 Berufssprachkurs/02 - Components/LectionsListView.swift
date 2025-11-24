//
//  LectionsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct LectionsListView: View {
    @ObservedObject var dataService: DataService
    @State private var expandedLections: Set<Int> = []
    @State private var isVerbenExpanded = false
    
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
        List {
            // Check all button header
            SwiftUI.Section {
                EmptyView()
            } header: {
                HStack {
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dataService.toggleAllLections()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: dataService.areAllLectionsCompleted() ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(dataService.areAllLectionsCompleted() ? Color("AppGreen") : .secondary)
                                .symbolEffect(.bounce, value: dataService.areAllLectionsCompleted())
                            
                            Text(dataService.areAllLectionsCompleted() ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
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
            
            // Lections
            ForEach(dataService.lections) { lection in
                SwiftUI.Section {
                    if expandedLections.contains(lection.id) {
                        ForEach(lection.sections) { section in
                            SectionRowView(section: section, dataService: dataService)
                                .listRowBackground(Color("AppGreenExtraLight"))
                        }
                    }
                } header: {
                    LectionHeaderView(
                        lection: lection,
                        isExpanded: expandedLections.contains(lection.id),
                        onToggle: {
                            HapticManager.shared.selection()
                            if expandedLections.contains(lection.id) {
                                expandedLections.remove(lection.id)
                            } else {
                                expandedLections.insert(lection.id)
                            }
                        },
                        dataService: dataService
                    )
                }
            }
            
            // Special section: Verben mit Präpositionen
            SwiftUI.Section {
                if isVerbenExpanded {
                    ForEach(verbenPrepositions, id: \.id) { preposition in
                        SectionRowView(
                            section: preposition,
                            dataService: dataService
                        )
                        .listRowBackground(Color("AppGreenExtraLight"))
                    }
                }
            } header: {
                HStack(spacing: 12) {
                    // Checkmark button
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        dataService.toggleVerbenCompleted()
                    }) {
                        Image(systemName: dataService.isVerbenCompleted() ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(dataService.isVerbenCompleted() ? Color("AppGreen") : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    // Expand/collapse button
                    Button(action: {
                        HapticManager.shared.selection()
                        isVerbenExpanded.toggle()
                    }) {
                        HStack {
                            Image(systemName: "book.circle")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Verben mit Präpositionen")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isVerbenExpanded ? 90 : 0))
                                .animation(.easeInOut(duration: 0.2), value: isVerbenExpanded)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 70, for: .scrollContent)
    }
}

struct LectionHeaderView: View {
    let lection: Lection
    let isExpanded: Bool
    let onToggle: () -> Void
    @ObservedObject var dataService: DataService
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark button
            Button(action: {
                HapticManager.shared.lightImpact()
                dataService.toggleLectionCompleted(lectionId: lection.id)
            }) {
                Image(systemName: dataService.isLectionCompleted(lectionId: lection.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(dataService.isLectionCompleted(lectionId: lection.id) ? Color("AppGreen") : .secondary)
            }
            .buttonStyle(.plain)
            
            // Expand/collapse button
            Button(action: onToggle) {
                HStack {
                    Image(systemName: "\(lection.id).circle")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(lection.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct SectionRowView: View {
    let section: Section
    @ObservedObject var dataService: DataService
    
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
                HapticManager.shared.lightImpact()
                dataService.toggleSectionCompleted(sectionId: section.id)
            }) {
                Image(systemName: dataService.isSectionCompleted(sectionId: section.id) ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundColor(dataService.isSectionCompleted(sectionId: section.id) ? Color("AppGreen") : .secondary)
            }
            .buttonStyle(.plain)
            
            // NavigationLink for the rest of the row
            NavigationLink(destination: WordsListView(sectionId: section.id)
                .environmentObject(dataService)) {
                HStack(spacing: 12) {
                    // Section letter (only show for non-VERBEN sections)
                    if !sectionLetter.isEmpty && !isVerbenSection {
                        Text(sectionLetter.uppercased())
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // Section title
                    Text(section.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.leading, 16)
        .background(Color("AppGreenExtraLight"))
        .listRowBackground(Color("AppGreenExtraLight"))
    }
}

#Preview {
    LectionsListView(dataService: DataService())
        .background(Color("AppGreenLight"))
}

