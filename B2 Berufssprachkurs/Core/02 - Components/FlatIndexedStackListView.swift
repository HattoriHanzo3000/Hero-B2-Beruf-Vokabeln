//
//  FlatIndexedStackListView.swift
//  B2 Berufssprachkurs
//
//  Shared root list for flat stack categories (Verbs, Adjectives).
//

import SwiftUI

struct FlatIndexedStackListView: View {
    @ObservedObject var dataService: DataService
    let accent: Color
    let icon: String
    let title: String
    let rows: [Section]
    let stackHeaderId: String
    let selectAllId: String
    let rowIdPrefix: String
    let scrollBinding: Binding<String?>
    let isAllSelected: Bool
    let onToggleAll: () -> Void
    /// When `true`, row is non-interactive except paywall (e.g. Verben **auf**–**zu** without Pro).
    var isRowLocked: (Section) -> Bool = { _ in false }
    var onLockedInteraction: () -> Void = {}

    var body: some View {
        StackRootListShell {
            List {
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    ScrollableStackRootHeader(
                        accent: accent,
                        icon: icon,
                        title: title
                    )
                    .id(stackHeaderId)
                }

                // Select-all header + rows in one section: keeps vertical gap tight (see `stackRootFlatListChrome` — plain list).
                SwiftUI.Section {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, section in
                        FlatIndexedStackRow(
                            section: section,
                            rowNumber: index + 1,
                            accent: accent,
                            dataService: dataService,
                            isLocked: isRowLocked(section),
                            onPaywall: onLockedInteraction
                        )
                        .listRowBackground(Color.clear)
                        .id("\(rowIdPrefix)-\(section.id)")
                    }
                } header: {
                    StackListSelectAllHeader(
                        isSelected: isAllSelected,
                        fontDesign: .default,
                        action: onToggleAll
                    )
                    .id(selectAllId)
                }
            }
            .stackRootFlatListChrome(scrollPosition: scrollBinding, bottomMargin: FlashcardsButton.fabSize + 24)
        }
    }
}

private struct FlatIndexedStackRow: View {
    let section: Section
    let rowNumber: Int
    let accent: Color
    @ObservedObject var dataService: DataService
    var isLocked: Bool = false
    var onPaywall: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme

    /// Flat lists have no parent lection; completed rows use the same “full” gray as General Words subsection rows when the lection is complete.
    private var checkmarkFillColor: Color {
        guard dataService.isSectionCompleted(sectionId: section.id) else { return .secondary }
        return CompletionCheckmarkPalette.fullFill(colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if isLocked {
                    onPaywall()
                } else {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.toggleSectionCompleted(sectionId: section.id)
                    }
                }
            } label: {
                Image(systemName: dataService.isSectionCompleted(sectionId: section.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(.subheadline, design: .default).weight(.medium))
                    .foregroundColor(checkmarkFillColor)
                    .symbolEffect(.bounce, value: dataService.isSectionCompleted(sectionId: section.id))
            }
            .buttonStyle(.plain)

            rowLabel
        }
        .opacity(isLocked ? 0.65 : 1.0)
    }

    @ViewBuilder
    private var rowLabel: some View {
        let label = HStack(spacing: 12) {
            Image(systemName: "\(rowNumber).circle.fill")
                .font(.system(.title2, design: .default).weight(.medium))
                .foregroundColor(accent)
                .accessibilityHidden(true)

            Text(section.title)
                .font(.system(.title3, design: .default))
                .foregroundColor(.primary)

            if isLocked {
                ProShieldBadge(
                    label: "PRO",
                    color: Color.primary.opacity(0.72),
                    showShimmer: false,
                    style: .compact
                )
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)

        if isLocked {
            Button(action: onPaywall) {
                label
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                WordsListView(sectionId: section.id)
                    .environmentObject(dataService)
            } label: {
                label
            }
        }
    }
}
