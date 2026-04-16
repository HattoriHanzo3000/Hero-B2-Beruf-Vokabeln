//
//  WordOfTheDayView.swift
//  B2 Berufssprachkurs
//
//  Widget layout for the daily word card across small and medium families.
//  Created: 07.04.26.
//

import SwiftUI
import WidgetKit

// MARK: - View

struct WordOfTheDayView: View {
    // MARK: State

    var entry: WordOfTheDayEntry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: Colors

    private var germanWordColor: Color {
        if widgetRenderingMode == .fullColor {
            switch colorScheme {
            case .dark:
                return Color.white.opacity(0.96)
            case .light:
                fallthrough
            @unknown default:
                return Color.white.opacity(0.98)
            }
        }
        return .primary
    }

    private var translationColor: Color {
        widgetRenderingMode == .fullColor
            ? Color.white.opacity(colorScheme == .dark ? 0.90 : 0.94)
            : .primary.opacity(0.92)
    }

    private var exampleColor: Color {
        widgetRenderingMode == .fullColor
            ? Color.white.opacity(colorScheme == .dark ? 0.78 : 0.84)
            : .secondary
    }

    // MARK: View Layout

    var body: some View {
        HStack(spacing: 12) {
            rightContentPane
            if showsMascot {
                rightMascotPane
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: Layout Rules

    private var showsMascot: Bool {
        widgetFamily != .systemSmall
    }

    private var germanWordLineLimit: Int {
        showsMascot ? 2 : 3
    }

    private var germanWordFont: Font {
        .system(.headline, design: .rounded, weight: .semibold)
    }

    private var translationLineLimit: Int {
        if isAccessibilityDynamicType { return 1 }
        return showsMascot ? 2 : 1
    }

    private var exampleLineLimit: Int {
        if isAccessibilityDynamicType { return showsMascot ? 1 : 0 }
        return showsMascot ? 3 : 2
    }

    private var showsExample: Bool {
        exampleLineLimit > 0
    }

    private var isAccessibilityDynamicType: Bool {
        dynamicTypeSize >= .accessibility1
    }

    private var contentPadding: EdgeInsets {
        if showsMascot {
            return EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0)
        }
        return EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
    }

    private var contentVerticalSpacing: CGFloat {
        showsMascot ? 10 : 6
    }

    private var titleStackSpacing: CGFloat {
        showsMascot ? 3 : 2
    }

    private var rightMascotPane: some View {
        VStack {
            Spacer(minLength: 0)
            mascotImageView
            Spacer(minLength: 0)
        }
        .frame(width: 92, alignment: .trailing)
        .frame(maxHeight: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private var mascotImageView: some View {
        if widgetRenderingMode == .fullColor {
            Image("Mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(x: -1, y: 1)
                .frame(maxWidth: 87, maxHeight: 87)
        } else {
            // Tinted/clear widget rendering can resolve dark asset variants even in daytime.
            // Keep the mascot in its daytime variant for accented rendering modes.
            Image("Mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .environment(\.colorScheme, .light)
                .scaleEffect(x: -1, y: 1)
                .frame(maxWidth: 87, maxHeight: 87)
        }
    }

    private var rightContentPane: some View {
        VStack(alignment: .leading, spacing: contentVerticalSpacing) {
            if showsMascot {
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: titleStackSpacing) {
                Text(entry.word)
                    .font(germanWordFont)
                    .foregroundStyle(germanWordColor)
                    .lineLimit(germanWordLineLimit)
                    .minimumScaleFactor(0.84)
                    .allowsTightening(true)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(3)

                if let translation = normalized(entry.translation) {
                    Text(translation)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(translationColor)
                        .lineLimit(translationLineLimit)
                        .minimumScaleFactor(0.84)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsExample {
                Text(normalized(entry.exampleSentence) ?? localizedString("widget_word_example_missing"))
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundStyle(exampleColor)
                    .italic()
                    .lineLimit(exampleLineLimit)
                    .minimumScaleFactor(0.82)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
            if showsMascot {
                Spacer(minLength: 0)
            }
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Helpers

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func localizedString(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", comment: "")
    }
}
