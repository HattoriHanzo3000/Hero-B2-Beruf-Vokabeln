//
//  ToolbarAccessoryButtonStyles.swift
//  B2 Berufssprachkurs
//
//  Segmented control styles (translation keyboard accessory, word header).
//

import SwiftUI

enum GroupedButtonPosition {
    case leading
    case middle
    case trailing
}

struct GroupedToolbarButtonStyle: ButtonStyle {
    let isSelected: Bool
    let accentColor: Color
    let position: GroupedButtonPosition

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(groupedButtonBackground)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    private var groupedButtonBackground: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
    }
}

struct CircularLiquidGlassButtonStyle: ButtonStyle {
    let isSelected: Bool
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(liquidGlassCircle)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    private var liquidGlassCircle: some View {
        Circle()
            .fill(.regularMaterial)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
