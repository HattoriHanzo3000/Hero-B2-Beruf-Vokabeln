//
//  BouncingSelectionCheckmark.swift
//  B2 Berufssprachkurs
//

import SwiftUI

/// Same interaction as list selection elsewhere: spring + SF Symbol bounce.
struct BouncingSelectionCheckmark: View {
    let isSelected: Bool
    /// Card headers (lection / stacks 13–14) use callout; inner rows use subheadline like general words subsections.
    var isHeaderRow: Bool = false
    /// Toolbar “select all” uses `checkmark.circle` when off; list rows use plain `circle`.
    var outlineIsCheckmarkCircle: Bool = false
    var toolbarStyled: Bool = false

    private var symbolName: String {
        if isSelected { return "checkmark.circle.fill" }
        return outlineIsCheckmarkCircle ? "checkmark.circle" : "circle"
    }

    var body: some View {
        Image(systemName: symbolName)
            .foregroundStyle(isSelected ? Color.secondary : Color.secondary)
            .modifier(CheckmarkFontModifier(toolbarStyled: toolbarStyled, isHeaderRow: isHeaderRow))
            .symbolEffect(.bounce, value: isSelected)
    }

    private struct CheckmarkFontModifier: ViewModifier {
        let toolbarStyled: Bool
        let isHeaderRow: Bool

        @ViewBuilder
        func body(content: Content) -> some View {
            if toolbarStyled {
                content.navigationBarSymbolStyle()
            } else if isHeaderRow {
                content.font(.system(.callout, design: .default).weight(.medium))
            } else {
                content.font(.system(.subheadline, design: .default).weight(.medium))
            }
        }
    }
}
