import SwiftUI
import WidgetKit

struct WordOfTheDayView: View {
    var entry: WordOfTheDayEntry
    @Environment(\.colorScheme) var colorScheme

    private var germanWordColor: Color {
        switch colorScheme {
        case .dark:
            return Color("AppGreenSecond")
        case .light:
            fallthrough
        @unknown default:
            return Color("AppGreenThird")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            rightContentPane
            rightMascotPane
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var rightMascotPane: some View {
        VStack {
            Spacer(minLength: 0)
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .scaleEffect(x: -1, y: 1)
                .frame(maxWidth: 87, maxHeight: 87)
            Spacer(minLength: 0)
        }
        .frame(width: 92, alignment: .trailing)
        .frame(maxHeight: .infinity, alignment: .trailing)
    }

    private var rightContentPane: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer(minLength: 0)
            VStack(alignment: .center, spacing: 2) {
                Text(entry.word)
                    .font(.system(.headline, design: .default, weight: .medium))
                    .foregroundStyle(germanWordColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if let translation = normalized(entry.translation) {
                    Text(translation)
                        .font(.system(.body, design: .default, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 3)

            Text(normalized(entry.exampleSentence) ?? localizedString("widget_word_example_missing"))
                .font(.system(.subheadline, design: .default, weight: .regular))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(4)
                .minimumScaleFactor(0.82)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func localizedString(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", comment: "")
    }
}
