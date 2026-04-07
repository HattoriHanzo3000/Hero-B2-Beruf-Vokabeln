//
//  MyWordsOverflowMenu.swift
//  B2 Berufssprachkurs
//
//  Toolbar overflow: enter edit (when inactive), sort, print, delete all. Done uses the bar checkmark in MyWordsView.
//

import SwiftUI

struct MyWordsOverflowMenu: View {
    @Binding var editMode: EditMode
    @Binding var myWordsSortModeRaw: String

    let listSortMode: MyWordsListSortMode
    let hasEntries: Bool
    let onPrint: () -> Void
    let onRequestDeleteAll: () -> Void

    private var printMenuItemAccessibilityHint: String {
        Localizable.string(Localizable.wordListPrintA11yHint)
    }

    var body: some View {
        if editMode == .inactive {
            Button {
                HapticManager.shared.lightImpact()
                withAnimation(.easeInOut(duration: 0.2)) {
                    editMode = .active
                }
            } label: {
                Label(Localizable.string(Localizable.myWordsEdit), systemImage: "pencil")
            }
        }

        Menu {
            Menu {
                Button {
                    myWordsSortModeRaw = MyWordsListSortMode.nameAscending.rawValue
                    HapticManager.shared.selection()
                } label: {
                    sortMenuRow(title: Localizable.string(Localizable.myWordsSortAscending), isSelected: listSortMode == .nameAscending)
                }
                Button {
                    myWordsSortModeRaw = MyWordsListSortMode.nameDescending.rawValue
                    HapticManager.shared.selection()
                } label: {
                    sortMenuRow(title: Localizable.string(Localizable.myWordsSortDescending), isSelected: listSortMode == .nameDescending)
                }
            } label: {
                Text(Localizable.string(Localizable.myWordsSortTitle))
            }

            Menu {
                Button {
                    myWordsSortModeRaw = MyWordsListSortMode.dateAscending.rawValue
                    HapticManager.shared.selection()
                } label: {
                    sortMenuRow(
                        title: Localizable.string(Localizable.myWordsSortDateOldestFirst),
                        isSelected: listSortMode == .dateAscending
                    )
                }
                Button {
                    myWordsSortModeRaw = MyWordsListSortMode.dateDescending.rawValue
                    HapticManager.shared.selection()
                } label: {
                    sortMenuRow(
                        title: Localizable.string(Localizable.myWordsSortDateNewestFirst),
                        isSelected: listSortMode == .dateDescending
                    )
                }
            } label: {
                Text(Localizable.string(Localizable.myWordsSortCreationDate))
            }

            Button {
                myWordsSortModeRaw = MyWordsListSortMode.manual.rawValue
                HapticManager.shared.selection()
            } label: {
                sortMenuRow(title: Localizable.string(Localizable.myWordsSortManual), isSelected: listSortMode == .manual)
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Localizable.string(Localizable.myWordsSortBy))
                    Text(listSortMode.sortOverflowMenuSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }

        Button {
            guard hasEntries else { return }
            HapticManager.shared.lightImpact()
            onPrint()
        } label: {
            Label(
                Localizable.string(Localizable.myWordsPrint),
                systemImage: "printer"
            )
        }
        .disabled(!hasEntries)
        .accessibilityHint(printMenuItemAccessibilityHint)

        if hasEntries {
            Divider()
            Button(role: .destructive) {
                HapticManager.shared.heavyImpact()
                onRequestDeleteAll()
            } label: {
                Label(
                    Localizable.string(Localizable.myWordsDeleteAllToolbarLabel),
                    systemImage: "trash"
                )
            }
            .accessibilityHint(Localizable.string(Localizable.myWordsDeleteAllToolbarHint))
        }
    }

    private func sortMenuRow(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 8)
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
