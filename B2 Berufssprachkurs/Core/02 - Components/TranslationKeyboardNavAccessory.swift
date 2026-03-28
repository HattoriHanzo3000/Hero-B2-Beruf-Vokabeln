//
//  TranslationKeyboardNavAccessory.swift
//  B2 Berufssprachkurs
//
//  Segmented controls for the translation field’s input accessory: one native UIToolbar chrome only
//  (no extra capsule — avoids nested “bar inside bar”).
//

import SwiftUI

struct TranslationKeyboardNavAccessory: View {
    @ObservedObject var keyboardNav: WordListKeyboardNavBridge
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onDone: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button {
                onPrevious()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(GroupedToolbarButtonStyle(isSelected: false, accentColor: .primary, position: .leading))
            .disabled(!keyboardNav.canGoToPrevious)
            .accessibilityLabel("Previous word")
            .accessibilityHint("Navigate to the previous word in the list")

            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 0.5, height: 24)

            Button {
                onNext()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(GroupedToolbarButtonStyle(isSelected: false, accentColor: .primary, position: .middle))
            .disabled(!keyboardNav.canGoToNext)
            .accessibilityLabel("Next word")
            .accessibilityHint("Navigate to the next word in the list")

            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 0.5, height: 24)

            Button {
                onDone()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(GroupedToolbarButtonStyle(isSelected: false, accentColor: .primary, position: .trailing))
            .accessibilityLabel(Localizable.string(Localizable.myWordsDoneEditing))
            .accessibilityHint("Hide keyboard and finish input")
        }
        .frame(height: 44)
        .background(Color.clear)
        .fixedSize(horizontal: true, vertical: true)
    }
}
