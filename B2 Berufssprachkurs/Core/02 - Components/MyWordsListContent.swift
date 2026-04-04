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
    let onAddTap: () -> Void
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

                if editMode == .inactive {
                    Button {
                        onAddTap()
                    } label: {
                        HStack {
                            Spacer(minLength: 0)
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent)
                                .symbolRenderingMode(.hierarchical)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden, edges: .bottom)
                    .accessibilityLabel(Localizable.string(Localizable.myWordsAddWord))
                    .accessibilityHint(Localizable.string(Localizable.myWordsAddWordA11yHint))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
        .contentMargins(.bottom, FlashcardsButton.fabSize + 24, for: .scrollContent)
        .accessibilityLabel(Localizable.string(Localizable.myWordsListA11yLabel))
        .accessibilityHint(Localizable.string(Localizable.myWordsListA11yHint))
    }
}
