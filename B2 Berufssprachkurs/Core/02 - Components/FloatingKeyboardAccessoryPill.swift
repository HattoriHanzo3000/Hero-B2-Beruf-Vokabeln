//
//  FloatingKeyboardAccessoryPill.swift
//  B2 Berufssprachkurs
//
//  Unified liquid-glass capsule for keyboard navigation and dismiss.
//
//  Created: 21.04.26.
//

import SwiftUI

struct FloatingKeyboardAccessoryPill: View {
    // MARK: - State

    @State private var pressedZones: Set<PillZone> = []

    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    // MARK: - View Layout

    var body: some View {
        HStack(spacing: 0) {
            chevronGroup
            Spacer(minLength: 0)
            doneButton
        }
        .padding(.horizontal, FloatingAccessoryMetrics.contentHorizontalPadding)
        .frame(minHeight: FloatingAccessoryMetrics.pillHeight)
        .frame(maxWidth: .infinity)
        .background(pillBackground)
        .scaleEffect(isAnyPressed ? FloatingAccessoryMetrics.pressedScale : 1.0)
        .shadow(
            color: .black.opacity(isAnyPressed ? FloatingAccessoryMetrics.shadowOpacityPressed : FloatingAccessoryMetrics.shadowOpacityIdle),
            radius: isAnyPressed ? FloatingAccessoryMetrics.shadowRadiusPressed : FloatingAccessoryMetrics.shadowRadiusIdle,
            x: 0,
            y: isAnyPressed ? FloatingAccessoryMetrics.shadowYOffsetPressed : FloatingAccessoryMetrics.shadowYOffsetIdle
        )
        .animation(FloatingAccessoryMetrics.pressSpring, value: isAnyPressed)
    }

    // MARK: - Helpers

    private var isAnyPressed: Bool {
        !pressedZones.isEmpty
    }

    private var chevronGroup: some View {
        HStack(spacing: 0) {
            Button(action: onPrevious) {
                FloatingAccessoryIcon(systemName: "chevron.up")
            }
            .buttonStyle(LiquidGlassPressStyle(zone: .previous, pressedZones: $pressedZones))
            .disabled(!canGoPrevious)
            .accessibilityLabel(Localizable.string(Localizable.keyboardNavPreviousWordA11y))
            .accessibilityHint(Localizable.string(Localizable.keyboardNavPreviousWordHintA11y))

            Button(action: onNext) {
                FloatingAccessoryIcon(systemName: "chevron.down")
            }
            .buttonStyle(LiquidGlassPressStyle(zone: .next, pressedZones: $pressedZones))
            .disabled(!canGoNext)
            .accessibilityLabel(Localizable.string(Localizable.keyboardNavNextWordA11y))
            .accessibilityHint(Localizable.string(Localizable.keyboardNavNextWordHintA11y))
        }
    }

    private var doneButton: some View {
        Button(action: onDone) {
            FloatingAccessoryIcon(systemName: "checkmark", weight: .bold)
        }
        .buttonStyle(LiquidGlassPressStyle(zone: .done, pressedZones: $pressedZones))
        .accessibilityLabel(Localizable.string(Localizable.myWordsDoneEditing))
        .accessibilityHint(Localizable.string(Localizable.keyboardNavDoneHintA11y))
    }

    private var pillBackground: some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: FloatingAccessoryMetrics.rimLineWidth
                    )
            }
    }
}
