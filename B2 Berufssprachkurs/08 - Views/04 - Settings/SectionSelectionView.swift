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
                                HStack {
                                    Text(section.title)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    if selectedSectionIds.contains(section.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                            .fontWeight(.semibold)
                                    }
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
                            Text(lection.title)
                                .font(.headline)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Select Sections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSelection()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadSelection()
        }
    }
    
    private func loadSelection() {
        if selectedSections.isEmpty {
            // If empty, select all sections by default
            selectedSectionIds = Set(dataService.lections.flatMap { $0.sections.map { $0.id } })
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
}

#Preview {
    SectionSelectionView(
        selectedSections: .constant(""),
        dataService: DataService()
    )
}

