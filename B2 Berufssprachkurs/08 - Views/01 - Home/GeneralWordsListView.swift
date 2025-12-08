//
//  GeneralWordsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct GeneralWordsListView: View {
    @ObservedObject var dataService: DataService
    @State private var expandedLections: Set<Int> = []
    
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
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(dataService.areAllLectionsCompleted() ? Color.gray : .secondary)
                                .symbolEffect(.bounce, value: dataService.areAllLectionsCompleted())
                            
                            Text(dataService.areAllLectionsCompleted() ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.vertical, 0)
            }
            
            // Lections (only first 12)
            ForEach(Array(dataService.lections.prefix(12))) { lection in
                SwiftUI.Section {
                    if expandedLections.contains(lection.id) {
                        ForEach(lection.sections) { section in
                            SectionRowView(section: section, dataService: dataService)
                                .listRowBackground(Color.clear)
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
        .safeAreaInset(edge: .bottom) {
            BannerAd()
                .background(Color("AppGreenLight"))
        }
        .scrollContentBackground(.hidden)
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dataService.toggleLectionCompleted(lectionId: lection.id)
                }
            }) {
                Image(systemName: dataService.isLectionCompleted(lectionId: lection.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(dataService.isLectionCompleted(lectionId: lection.id) ? Color.gray : .secondary)
                    .symbolEffect(.bounce, value: dataService.isLectionCompleted(lectionId: lection.id))
            }
            .buttonStyle(.plain)
            
            // Expand/collapse button
            Button(action: onToggle) {
                HStack {
                    Image(systemName: "\(lection.id).circle.fill")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .foregroundColor(Color("AppGreen"))
                    
                    Text(lection.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dataService.toggleSectionCompleted(sectionId: section.id)
                }
            }) {
                Image(systemName: dataService.isSectionCompleted(sectionId: section.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(dataService.isSectionCompleted(sectionId: section.id) ? Color.gray : .secondary)
                    .symbolEffect(.bounce, value: dataService.isSectionCompleted(sectionId: section.id))
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
                            .foregroundColor(Color("AppGreen"))
                    }
                    
                    // Section title
                    Text(section.title)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.leading, 16)
    }
}

#Preview {
    GeneralWordsListView(dataService: DataService())
        .background(Color("AppGreenLight"))
}

