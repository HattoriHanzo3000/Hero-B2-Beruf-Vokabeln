//
//  WordListKeyboardNavigationToolbar.swift
//  B2 Berufssprachkurs
//
//  Keyboard accessory: previous/next on the leading side, flexible gap, trailing checkmark
//  (matches the width and layout of system keyboards / offer-code style bars).
//

import SwiftUI

struct WordListKeyboardNavigationToolbar: ToolbarContent {
    let canGoToPrevious: Bool
    let canGoToNext: Bool
    let goToPrevious: () -> Void
    let goToNext: () -> Void
    let dismissKeyboard: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            HStack(spacing: 0) {
                HStack(spacing: 24) {
                    Button {
                        HapticManager.shared.lightImpact()
                        goToPrevious()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.body.weight(.medium))
                            .imageScale(.large)
                    }
                    .disabled(!canGoToPrevious)
                    .accessibilityLabel("Previous word")
                    .accessibilityHint("Navigate to the previous word in the list")

                    Button {
                        HapticManager.shared.lightImpact()
                        goToNext()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.body.weight(.medium))
                            .imageScale(.large)
                    }
                    .disabled(!canGoToNext)
                    .accessibilityLabel("Next word")
                    .accessibilityHint("Navigate to the next word in the list")
                }

                Spacer(minLength: 0)

                Button {
                    HapticManager.shared.lightImpact()
                    dismissKeyboard()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .imageScale(.large)
                }
                .accessibilityLabel(Localizable.string(Localizable.myWordsDoneEditing))
                .accessibilityHint("Hide keyboard and finish input")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
    }
}
