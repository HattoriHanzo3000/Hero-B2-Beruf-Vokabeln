//
//  MyWordsListContent.swift
//  B2 Berufssprachkurs
//
//  List body: header, rows, add button. (My Words is gated on Home for Pro users only.)
//

import SwiftUI

struct MyWordsListContent<Row: View>: View {
    let accent: Color
    let displayedEntries: [CustomWordEntry]
    let listSortMode: MyWordsListSortMode
    @Binding var editMode: EditMode
    let onMove: (IndexSet, Int) -> Void
    @ViewBuilder let row: (CustomWordEntry) -> Row

    var body: some View {
        List {
            SwiftUI.Section {
                EmptyView()
            } header: {
                ScrollableStackRootHeader(
                    accent: accent,
                    icon: "person.fill",
                    title: Localizable.string(Localizable.myWords).replacingOccurrences(of: "\n", with: " "),
                    showsDivider: false
                )
            }

            SwiftUI.Section {
                Group {
                    if listSortMode == .manual {
                        ForEach(displayedEntries) { entry in
                            row(entry)
                        }
                        .onMove(perform: onMove)
                    } else {
                        ForEach(displayedEntries) { entry in
                            row(entry)
                        }
                    }
                }

            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 6, for: .scrollContent)
        .contentMargins(.bottom, FlashcardsButton.fabSize + 24, for: .scrollContent)
        .contentMargins(.horizontal, 0, for: .scrollContent)
        .accessibilityLabel(Localizable.string(Localizable.myWordsListA11yLabel))
        .accessibilityHint(Localizable.string(Localizable.myWordsListA11yHint))
    }
}
