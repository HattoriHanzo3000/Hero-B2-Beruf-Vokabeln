//
//  StudySectionOriginHintControl.swift
//  B2 Berufssprachkurs
//
//  Bottom-left study hint: info icon reveals the section-origin badge on demand.
//

import SwiftUI

struct StudySectionOriginHintControl: View {
    let sectionId: String
    let germanWord: String
    let accentColor: Color
    @Binding var isRevealed: Bool

    @Environment(\.colorScheme) private var colorScheme

    private static let controlSize: CGFloat = 24

    private var badgeCaption: String {
        StudySectionOriginFormatting.badgeCaption(sectionId: sectionId, germanWord: germanWord)
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                HapticManager.shared.lightImpact()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRevealed.toggle()
                }
            } label: {
                Image(systemName: isRevealed ? "info.circle.fill" : "info.circle")
                    .font(.system(size: Self.controlSize, weight: .regular, design: .default))
                    .foregroundColor(isRevealed ? accentColor : .secondary)
                    .frame(width: Self.controlSize, height: Self.controlSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isRevealed
                    ? Localizable.string(Localizable.studySectionHintHideA11y)
                    : Localizable.string(Localizable.studySectionHintShowA11y)
            )
            .accessibilityValue(isRevealed ? badgeCaption : "")

            if isRevealed {
                Text(badgeCaption)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 6)
                    .frame(height: Self.controlSize)
                    .background(
                        Capsule(style: .continuous)
                            .fill(accentColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .accessibilityHidden(true)
            }
        }
    }
}
