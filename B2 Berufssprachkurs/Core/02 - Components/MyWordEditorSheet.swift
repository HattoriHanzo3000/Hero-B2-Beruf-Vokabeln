//
//  MyWordEditorSheet.swift
//  B2 Berufssprachkurs
//
//  Add or edit a custom word (shared navigation, keyboard accessory, and form).
//

import SwiftData
import SwiftUI

struct MyWordEditorSheet: View {
    enum Mode {
        case add
        case edit(CustomWordEntry)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: MyWordSheetField?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()

    let mode: Mode
    /// When `true` (e.g. Lock Screen Quick Add), focuses the German field after the sheet is on-screen so the keyboard appears quickly.
    private let autofocusGermanOnAppear: Bool

    init(mode: Mode, autofocusGermanOnAppear: Bool = false) {
        self.mode = mode
        self.autofocusGermanOnAppear = autofocusGermanOnAppear
    }

    @State private var german = ""
    @State private var translation = ""
    @State private var example = ""
    @State private var explanation = ""
    @State private var synonym = ""

    private var canSave: Bool {
        !german.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navigationTitle: String {
        switch mode {
        case .add:
            return Localizable.string(Localizable.myWordsAddWord)
        case .edit:
            return Localizable.string(Localizable.myWordsEditWord)
        }
    }

    private var showsFloatingAccessory: Bool {
        focusedField != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    MyWordFormFields(
                        german: $german,
                        translation: $translation,
                        example: $example,
                        explanation: $explanation,
                        synonym: $synonym,
                        focusedField: $focusedField
                    )
                }
            }
            .floatingKeyboardAccessory(
                isVisible: showsFloatingAccessory,
                canGoPrevious: keyboardNavBridge.canGoToPrevious,
                canGoNext: keyboardNavBridge.canGoToNext,
                onPrevious: {
                    HapticManager.shared.lightImpact()
                    focusPreviousField()
                },
                onNext: {
                    HapticManager.shared.lightImpact()
                    focusNextField()
                },
                onDone: {
                    HapticManager.shared.lightImpact()
                    focusedField = nil
                }
            )
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(Localizable.string(Localizable.cancel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .navigationBarSymbolStyle()
                            .foregroundStyle(canSave ? Color.primary : Color.primary.opacity(0.34))
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(Localizable.string(Localizable.ok))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if case let .edit(entry) = mode {
                german = entry.german
                translation = entry.translation
                example = entry.example ?? ""
                explanation = entry.explanation ?? ""
                synonym = entry.synonym ?? ""
            }
            syncKeyboardNavBridge()
            if case .add = mode, autofocusGermanOnAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    focusedField = .german
                }
            }
        }
        .onChange(of: focusedField) { _, _ in
            syncKeyboardNavBridge()
        }
    }

    private func nextSortIndex() -> Int {
        let descriptor = FetchDescriptor<CustomWordEntry>()
        guard let all = try? modelContext.fetch(descriptor) else { return 0 }
        return (all.map(\.sortIndex).max() ?? -1) + 1
    }

    private func saveAndDismiss() {
        let g = german.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !g.isEmpty else { return }

        switch mode {
        case .add:
            let ex = example.trimmingCharacters(in: .whitespacesAndNewlines)
            let exp = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
            let syn = synonym.trimmingCharacters(in: .whitespacesAndNewlines)

            let entry = CustomWordEntry(
                german: g,
                translation: translation.trimmingCharacters(in: .whitespacesAndNewlines),
                example: ex.isEmpty ? nil : ex,
                explanation: exp.isEmpty ? nil : exp,
                synonym: syn.isEmpty ? nil : syn,
                sortIndex: nextSortIndex()
            )
            modelContext.insert(entry)
            try? modelContext.save()
            HapticManager.shared.lightImpact()
            dismiss()

        case .edit(let entry):
            let ex = example.trimmingCharacters(in: .whitespacesAndNewlines)
            let exp = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
            let syn = synonym.trimmingCharacters(in: .whitespacesAndNewlines)

            entry.german = g
            entry.translation = translation.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.example = ex.isEmpty ? nil : ex
            entry.explanation = exp.isEmpty ? nil : exp
            entry.synonym = syn.isEmpty ? nil : syn

            try? modelContext.save()
            HapticManager.shared.lightImpact()
            dismiss()
        }
    }

    private func focusPreviousField() {
        focusedField = focusedField?.previous
    }

    private func focusNextField() {
        focusedField = focusedField?.next
    }

    private func syncKeyboardNavBridge() {
        keyboardNavBridge.syncCanNavigate(
            canPrevious: focusedField?.previous != nil,
            canNext: focusedField?.next != nil
        )
    }
}
