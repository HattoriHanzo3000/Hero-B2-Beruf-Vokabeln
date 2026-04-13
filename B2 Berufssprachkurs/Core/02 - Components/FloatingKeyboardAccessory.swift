//
//  FloatingKeyboardAccessory.swift
//  B2 Berufssprachkurs
//
//  Shared floating keyboard accessory modifier and host view.
//

import SwiftUI

private enum FloatingAccessoryButtonPosition {
    case leading
    case middle
    case trailing
}

private struct FloatingLiquidGlassButtonStyle: ButtonStyle {
    let position: FloatingAccessoryButtonPosition
    let cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .background(liquidGlassBackground)
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }

    @ViewBuilder
    private var liquidGlassBackground: some View {
        switch position {
        case .leading:
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .fill(Color.clear)
        case .middle:
            Rectangle()
                .fill(Color.clear)
        case .trailing:
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: cornerRadius,
                style: .continuous
            )
            .fill(Color.clear)
        }
    }
}

private struct FloatingKeyboardAccessoryView: View {
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(FloatingLiquidGlassButtonStyle(position: .leading))
            .disabled(!canGoPrevious)
            .accessibilityLabel(Localizable.string(Localizable.keyboardNavPreviousWordA11y))
            .accessibilityHint(Localizable.string(Localizable.keyboardNavPreviousWordHintA11y))

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 0.5, height: 24)

            Button(action: onNext) {
                Image(systemName: "chevron.down")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(FloatingLiquidGlassButtonStyle(position: .middle))
            .disabled(!canGoNext)
            .accessibilityLabel(Localizable.string(Localizable.keyboardNavNextWordA11y))
            .accessibilityHint(Localizable.string(Localizable.keyboardNavNextWordHintA11y))

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 0.5, height: 24)

            Button(action: onDone) {
                Image(systemName: "checkmark")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(FloatingLiquidGlassButtonStyle(position: .trailing))
            .accessibilityLabel(Localizable.string(Localizable.myWordsDoneEditing))
            .accessibilityHint(Localizable.string(Localizable.keyboardNavDoneHintA11y))
        }
        .frame(height: 44)
        .background(Color.clear)
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct FloatingKeyboardAccessoryHostView: View {
    @ObservedObject var keyboardNav: WordListKeyboardNavBridge
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    var body: some View {
        FloatingKeyboardAccessoryView(
            canGoPrevious: keyboardNav.canGoToPrevious,
            canGoNext: keyboardNav.canGoToNext,
            onPrevious: onPrevious,
            onNext: onNext,
            onDone: onDone
        )
    }
}

struct FloatingKeyboardAccessoryModifier: ViewModifier {
    let isVisible: Bool
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if isVisible {
                FloatingKeyboardAccessoryView(
                    canGoPrevious: canGoPrevious,
                    canGoNext: canGoNext,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onDone: onDone
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.45),
                                            .white.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.22),
                                            .white.opacity(0.06)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                }
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isVisible)
    }
}

extension View {
    func floatingKeyboardAccessory(
        isVisible: Bool,
        canGoPrevious: Bool,
        canGoNext: Bool,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        modifier(
            FloatingKeyboardAccessoryModifier(
                isVisible: isVisible,
                canGoPrevious: canGoPrevious,
                canGoNext: canGoNext,
                onPrevious: onPrevious,
                onNext: onNext,
                onDone: onDone
            )
        )
    }
}
