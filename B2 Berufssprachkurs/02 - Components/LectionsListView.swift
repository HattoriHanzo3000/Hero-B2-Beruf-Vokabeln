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
    
    var body: some View {
        List {
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
                    // Section letter
                    if !sectionLetter.isEmpty {
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

