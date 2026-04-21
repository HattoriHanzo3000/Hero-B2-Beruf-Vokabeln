//
//  FloatingKeyboardAccessory.swift
//  B2 Berufssprachkurs
//
//  SwiftUI modifier, UIKit host wrapper, and canvas preview for the keyboard pill.
//
//  Created: 21.04.26.
//

import SwiftUI

// MARK: - View Layout

struct FloatingKeyboardAccessoryHostView: View {
    @ObservedObject var keyboardNav: WordListKeyboardNavBridge
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDone: () -> Void

    var body: some View {
        FloatingKeyboardAccessoryPill(
            canGoPrevious: keyboardNav.canGoToPrevious,
            canGoNext: keyboardNav.canGoToNext,
            onPrevious: onPrevious,
            onNext: onNext,
            onDone: onDone
        )
        .padding(.horizontal, FloatingAccessoryMetrics.horizontalInset)
        .padding(.bottom, FloatingAccessoryMetrics.bottomGap)
        .frame(maxWidth: .infinity)
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
                FloatingKeyboardAccessoryPill(
                    canGoPrevious: canGoPrevious,
                    canGoNext: canGoNext,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onDone: onDone
                )
                .padding(.horizontal, FloatingAccessoryMetrics.horizontalInset)
                .padding(.bottom, FloatingAccessoryMetrics.bottomGap)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(FloatingAccessoryMetrics.visibilitySpring, value: isVisible)
    }
}

// MARK: - Helpers

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

// MARK: - Preview

#Preview("Floating Pill — Keyboard Simulation") {
    GeometryReader { proxy in
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.blue.opacity(0.35), .purple.opacity(0.35), .pink.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    Color(uiColor: .systemGray5)
                        .frame(height: proxy.size.height * FloatingAccessoryMetrics.previewKeyboardStripHeightFactor)

                    VStack(spacing: FloatingAccessoryMetrics.bottomGap) {
                        Text(Localizable.string(Localizable.keyboardAccessoryPreviewSimulatedKeyboard))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FloatingKeyboardAccessoryPill(
                            canGoPrevious: true,
                            canGoNext: true,
                            onPrevious: {},
                            onNext: {},
                            onDone: {}
                        )
                        .padding(.horizontal, FloatingAccessoryMetrics.horizontalInset)
                    }
                    .padding(.top, FloatingAccessoryMetrics.contentHorizontalPadding)
                    .offset(y: -(FloatingAccessoryMetrics.pillHeight + FloatingAccessoryMetrics.bottomGap))
                }
            }
        }
    }
}
