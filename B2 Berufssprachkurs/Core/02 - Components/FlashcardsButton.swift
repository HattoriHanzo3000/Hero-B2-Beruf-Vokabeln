//
//  FlashcardsButton.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

/// When a floating practice control is disabled, how a tap should behave.
enum FloatingPracticeInactiveTapBehavior: Equatable {
    /// Explains category checkmarks (stack roots).
    case showNeedSelectionAlert
    /// Heavy haptic only (e.g. My Words empty list).
    case silent
}

/// Circular flashcards button used across all practice modes.
struct FlashcardsButton: View {
    let isEnabled: Bool
    let accent: Color
    var inactiveTapBehavior: FloatingPracticeInactiveTapBehavior = .showNeedSelectionAlert
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showNeedSelectionAlert = false

    static let fabSize: CGFloat = 84 // 56 × 1.5

    private var symbolPointSize: CGFloat { 33 }

    private var inactiveFill: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.39, green: 0.39, blue: 0.41)
        case .light:
            return Color(red: 0.58, green: 0.58, blue: 0.60)
        @unknown default:
            return Color(red: 0.58, green: 0.58, blue: 0.60)
        }
    }

    private var fill: Color {
        isEnabled ? accent : inactiveFill
    }

    var body: some View {
        Button {
            if isEnabled {
                HapticManager.shared.mediumImpact()
                action()
            } else {
                HapticManager.shared.heavyImpact()
                if inactiveTapBehavior == .showNeedSelectionAlert {
                    showNeedSelectionAlert = true
                }
            }
        } label: {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: symbolPointSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Self.fabSize, height: Self.fabSize)
                .background {
                    Circle().fill(fill)
                }
                .shadow(
                    color: isEnabled ? accent.opacity(0.35) : Color.black.opacity(0.12),
                    radius: isEnabled ? 12 : 6,
                    x: 0,
                    y: isEnabled ? 6 : 3
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localizable.string(Localizable.practiceWithCards))
        .alert(
            Localizable.string(Localizable.practiceNeedSelectionTitle),
            isPresented: $showNeedSelectionAlert
        ) {
            Button(Localizable.string(Localizable.ok)) {
                showNeedSelectionAlert = false
            }
        } message: {
            Text(Localizable.string(Localizable.practiceNeedSelectionMessage))
        }
    }
}

extension FlashcardsButton {
    /// Trailing FAB row for `safeAreaInset(edge: .bottom)` (matches the stack root layout).
    static func bottomTrailingInset(
        isEnabled: Bool,
        accent: Color,
        inactiveTapBehavior: FloatingPracticeInactiveTapBehavior = .showNeedSelectionAlert,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            FlashcardsButton(
                isEnabled: isEnabled,
                accent: accent,
                inactiveTapBehavior: inactiveTapBehavior,
                action: action
            )
        }
        .padding(.trailing, 16)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .frame(height: fabSize + 14)
    }
}

