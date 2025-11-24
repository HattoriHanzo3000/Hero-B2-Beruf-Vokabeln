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
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSectionIds: Set<String> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                List {
                    ForEach(dataService.lections) { lection in
                        SwiftUI.Section {
                            ForEach(lection.sections) { section in
                                HStack(spacing: 12) {
                                    Text(getSectionLetter(sectionId: section.id))
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24, alignment: .leading)
                                    
                                    Text(section.title)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedSectionIds.contains(section.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSectionIds.contains(section.id) ? Color("AppGreen") : .secondary)
                                        .fontWeight(.semibold)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticManager.shared.lightImpact()
                                    if selectedSectionIds.contains(section.id) {
                                        selectedSectionIds.remove(section.id)
                                    } else {
                                        selectedSectionIds.insert(section.id)
                                    }
                                }
                            }
                        } header: {
                            HStack(spacing: 12) {
                                Text("\(lection.id)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, alignment: .leading)
                                
                                Text(lection.title)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: isLectionFullySelected(lection: lection) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isLectionFullySelected(lection: lection) ? Color("AppGreen") : .secondary)
                                    .fontWeight(.semibold)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.lightImpact()
                                toggleLectionSelection(lection: lection)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle(Localizable.string(Localizable.sourceSections))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadSelection()
        }
        .onDisappear {
            saveSelection()
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
        let allSectionIds = Set(dataService.lections.flatMap { $0.sections.map { $0.id } })
        
        if selectedSectionIds == allSectionIds {
            // All selected, save as empty to mean "all"
            selectedSections = ""
        } else {
            selectedSections = selectedSectionIds.joined(separator: ",")
        }
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
            // Select all sections in this lection
            selectedSectionIds.formUnion(lectionSectionIds)
        }
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

