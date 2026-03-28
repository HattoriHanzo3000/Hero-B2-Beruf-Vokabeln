//
//  WordTranslationEditSheet.swift
//  B2 Berufssprachkurs
//
//  Half-sheet editor for a single user translation (word lists).
//  Matches My Words add/edit sheets: List field styling, × / checkmark toolbar.
//

import SwiftUI
import SwiftData

struct WordTranslationEditSheet: View {
    let word: Word

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var progressMatches: [WordProgress]
    @State private var draft: String = ""

    init(word: Word) {
        self.word = word
        let id = word.id
        _progressMatches = Query(filter: #Predicate<WordProgress> { $0.wordId == id })
    }

    private var canConfirm: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section {
                    TextField(
                        Localizable.string(Localizable.translation),
                        text: $draft,
                        axis: .vertical
                    )
                    .lineLimit(1...)
                    .fixedSize(horizontal: false, vertical: true)
                    .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle(word.german)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(Localizable.string(Localizable.cancel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(canConfirm ? Color.accentColor : .secondary)
                    }
                    .disabled(!canConfirm)
                    .accessibilityLabel(Localizable.string(Localizable.ok))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            draft = progressMatches.first?.translation ?? ""
        }
    }

    private func saveAndDismiss() {
        guard canConfirm else { return }
        WordProgress.upsertTranslation(
            wordId: word.id,
            text: draft,
            in: modelContext
        )
        HapticManager.shared.lightImpact()
        dismiss()
    }
}
