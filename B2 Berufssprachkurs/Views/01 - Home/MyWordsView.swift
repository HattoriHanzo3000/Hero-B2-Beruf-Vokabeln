//
//  MyWordsView.swift
//  B2 Berufssprachkurs
//
//  Personal vocabulary list; entries are SwiftData + CloudKit (same container as WordProgress).
//

import os
import SwiftData
import SwiftUI

struct MyWordsView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\CustomWordEntry.sortIndex, order: .forward),
        SortDescriptor(\CustomWordEntry.createdAt, order: .forward)
    ]) private var customWordEntries: [CustomWordEntry]

    @AppStorage(MyWordsListSortMode.appStorageKey) private var myWordsSortModeRaw: String = MyWordsListSortMode.manual.rawValue

    @State private var showAddWordSheet = false
    @State private var navigateToStudy = false
    @State private var editMode: EditMode = .inactive
    @State private var editingEntry: CustomWordEntry?
    @State private var showDeleteAllConfirmation = false

    private var accent: Color { Color("AppRed") }

    private var myWordsListSortMode: MyWordsListSortMode {
        MyWordsListSortMode.resolved(from: myWordsSortModeRaw)
    }

    /// Rows in the order the user chose (custom / name / date); also used for share/PDF.
    private var displayedMyWordEntries: [CustomWordEntry] {
        myWordsListSortMode.sortedEntries(from: customWordEntries)
    }

    var body: some View {
        ZStack {
            accent.opacity(0.08)
                .ignoresSafeArea()

            MyWordsListContent(
                accent: accent,
                displayedEntries: displayedMyWordEntries,
                listSortMode: myWordsListSortMode,
                editMode: $editMode,
                onMove: applyMove,
                onAddTap: {
                    HapticManager.shared.lightImpact()
                    showAddWordSheet = true
                },
                row: { entry in
                    myWordListRow(for: entry)
                }
            )
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    MyWordsOverflowMenu(
                        editMode: $editMode,
                        myWordsSortModeRaw: $myWordsSortModeRaw,
                        listSortMode: myWordsListSortMode,
                        hasEntries: !customWordEntries.isEmpty,
                        onPrint: { performMyWordsPrintAction() },
                        onRequestDeleteAll: { showDeleteAllConfirmation = true }
                    )
                } label: {
                    Image(systemName: "ellipsis")
                        .navigationBarSymbolStyle()
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel(Localizable.string(Localizable.myWordsMoreOptionsA11y))
            }
        }
        .sheet(isPresented: $showAddWordSheet) {
            MyWordEditorSheet(mode: .add)
        }
        .sheet(item: $editingEntry) { entry in
            MyWordEditorSheet(mode: .edit(entry))
        }
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: DataService.userMyWordsSectionId,
                studyAllMode: true,
                favoritesOnly: false,
                categoryFilter: nil
            )
            .environmentObject(dataService)
        }
        .onAppear {
            let migrated = MyWordsListSortMode.migratedAppStorageValue(from: myWordsSortModeRaw)
            if migrated != myWordsSortModeRaw {
                myWordsSortModeRaw = migrated
            }
            CustomWordEntry.renumberSortOrderIfNeeded(in: modelContext)
        }
        .alert(
            Localizable.string(Localizable.myWordsDeleteAllTitle),
            isPresented: $showDeleteAllConfirmation
        ) {
            Button(Localizable.string(Localizable.cancel), role: .cancel) {}
            Button(Localizable.string(Localizable.myWordsDeleteAllConfirm), role: .destructive) {
                deleteAllMyWords()
            }
        } message: {
            Text(Localizable.string(Localizable.myWordsDeleteAllMessage))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FlashcardsButton.bottomTrailingInset(
                isEnabled: !customWordEntries.isEmpty,
                accent: accent,
                inactiveTapBehavior: .silent
            ) {
                navigateToStudy = true
            }
        }
        .hidesBottomBarWhenPushed(true)
    }

    private func performMyWordsPrintAction() {
        guard !customWordEntries.isEmpty else { return }
        HapticManager.shared.lightImpact()
        let pdfURL: URL
        do {
            pdfURL = try MyWordsPDFExport.generatePDF(displayedEntries: displayedMyWordEntries)
        } catch {
            AppLog.pdf.error("Failed to generate My Words PDF: \(error.localizedDescription, privacy: .public)")
            return
        }
        let job = Localizable.string(Localizable.myWords).replacingOccurrences(of: "\n", with: " ")
        WordListPrintPresenter.present(pdfURL: pdfURL, jobName: job)
    }

    @ViewBuilder
    private func myWordEditModeRow(entry: CustomWordEntry, word: Word) -> some View {
        MyWordRow(
            word: word,
            isFavorite: dataService.isFavorite(wordId: word.id),
            onEditTranslation: {},
            onFavoriteToggle: {},
            onDelete: { deleteEntry(entry) },
            openEditSheet: {
                HapticManager.shared.lightImpact()
                editingEntry = entry
            },
            translationButtonsEnabled: false
        )
        .accessibilityHint(Localizable.string(Localizable.myWordsEditRowHint))
    }

    private func deleteAllMyWords() {
        let entries = Array(customWordEntries)
        guard !entries.isEmpty else { return }

        CustomWordEntryDeletion.deleteAll(entries, dataService: dataService, modelContext: modelContext)

        editingEntry = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            editMode = .inactive
        }
        HapticManager.shared.mediumImpact()
    }

    private func deleteEntry(_ entry: CustomWordEntry) {
        if editingEntry?.id == entry.id {
            editingEntry = nil
        }
        CustomWordEntryDeletion.deleteSingle(entry, dataService: dataService, modelContext: modelContext)
        HapticManager.shared.mediumImpact()
    }

    private func applyMove(from source: IndexSet, to destination: Int) {
        guard myWordsListSortMode == .manual else { return }
        var ordered = displayedMyWordEntries
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, entry) in ordered.enumerated() {
            entry.sortIndex = i
        }
        try? modelContext.save()
        HapticManager.shared.lightImpact()
    }

    @ViewBuilder
    private func myWordListRow(for entry: CustomWordEntry) -> some View {
        let word = entry.asWord()
        Group {
            if editMode == .active {
                myWordEditModeRow(entry: entry, word: word)
            } else {
                MyWordRow(
                    word: word,
                    isFavorite: dataService.isFavorite(wordId: word.id),
                    onEditTranslation: { editingEntry = entry },
                    onFavoriteToggle: {
                        _ = dataService.toggleFavorite(wordId: word.id)
                        HapticManager.shared.lightImpact()
                    }
                )
            }
        }
        .id(entry.id)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, CustomWordEntry.self, configurations: config)
    NavigationStack {
        MyWordsView()
            .environmentObject(DataService())
    }
    .modelContainer(container)
}
