//
//  ToolbarButtonType.swift
//  B2 Berufssprachkurs
//
//  Toolbar button model, segmented control styles (word list, translation keyboard accessory).
//

import SwiftUI

enum ToolbarButtonType {
    case explanation
    case synonym
    case translation
    case example // For VERBEN sections

    var message: String {
        switch self {
        case .explanation: return Localizable.string(Localizable.explanation)
        case .synonym: return Localizable.string(Localizable.synonym)
        case .translation: return Localizable.string(Localizable.translation)
        case .example: return Localizable.string(Localizable.myWordsExampleLabel)
        }
    }

    var color: Color {
        switch self {
        case .explanation: return Color("AppOrange")
        case .synonym: return Color("AppGreen")
        case .translation: return Color("AppBlue")
        case .example: return Color("AppOrange") // Same as explanation
        }
    }

    var buttonText: String {
        switch self {
        case .explanation: return Localizable.string(Localizable.practiseWithExplanation)
        case .synonym: return Localizable.string(Localizable.practiseWithSynonym)
        case .translation: return Localizable.string(Localizable.practiseWithTranslation)
        case .example: return Localizable.string(Localizable.practiseWithExample)
        }
    }

    var icon: String {
        switch self {
        case .explanation: return "info"
        case .synonym: return "figure.2"
        case .translation: return "globe"
        case .example: return "ellipsis"
        }
    }
}

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
