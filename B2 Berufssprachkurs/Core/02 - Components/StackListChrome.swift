//
//  StackListChrome.swift
//  B2 Berufssprachkurs
//
//  Shared chrome for root stack lists (General Words, Verbs, Adjectives).
//

import SwiftUI

/// Neutral grays for list completion checkmarks (partial vs full / select-all).
enum CompletionCheckmarkPalette {
    /// Some items done — one step darker than a very light gray so it reads clearly.
    static func partialFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.40) : Color(white: 0.60)
    }

    /// Everything in scope selected (e.g. whole lection or “Alle auswählen”).
    static func fullFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.88) : Color(white: 0.26)
    }
}

/// Outer shell for root stack `List` screens: matches Verbs/Adjectives/General Words navigation chrome.
struct StackRootListShell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StackListSelectAllHeader: View {
    let isSelected: Bool
    var fontDesign: Font.Design = .default
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Button {
                HapticManager.shared.mediumImpact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    action()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(.subheadline, design: fontDesign).weight(.medium))
                        .foregroundColor(isSelected ? CompletionCheckmarkPalette.fullFill(colorScheme) : .secondary)
                        .symbolEffect(.bounce, value: isSelected)

                    Text(isSelected ? Localizable.string(Localizable.allSelected) : Localizable.string(Localizable.selectAll))
                        .font(.system(.caption, design: fontDesign).weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.vertical, 0)
    }
}

private struct StackRootListChromeModifier: ViewModifier {
    @Binding var scrollPosition: String?

    func body(content: Content) -> some View {
        content
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins(.bottom, 90, for: .scrollContent)
            .scrollPosition(id: $scrollPosition, anchor: .center)
    }
}

extension View {
    func stackRootListChrome(scrollPosition: Binding<String?>) -> some View {
        modifier(StackRootListChromeModifier(scrollPosition: scrollPosition))
    }
}
