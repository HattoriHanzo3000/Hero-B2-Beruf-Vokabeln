//
//  GroupedToolbar.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
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

struct GroupedToolbar: View {
    let onExplanationTap: () -> Void
    let onSynonymTap: () -> Void
    let onTranslationTap: () -> Void
    let onExampleTap: (() -> Void)?
    let onSettingsTap: (() -> Void)?
    @Binding var selectedButtonType: ToolbarButtonType
    let isVerbenMode: Bool // If true, show only translation and example buttons
    
    @State private var selectedButton: ToolbarButtonType = .translation
    
    init(onExplanationTap: @escaping () -> Void, onSynonymTap: @escaping () -> Void, onTranslationTap: @escaping () -> Void, onExampleTap: (() -> Void)? = nil, onSettingsTap: (() -> Void)? = nil, selectedButtonType: Binding<ToolbarButtonType>, isVerbenMode: Bool = false) {
        self.onExplanationTap = onExplanationTap
        self.onSynonymTap = onSynonymTap
        self.onTranslationTap = onTranslationTap
        self.onExampleTap = onExampleTap
        self.onSettingsTap = onSettingsTap
        self._selectedButtonType = selectedButtonType
        self.isVerbenMode = isVerbenMode
    }
    
    init(onExplanationTap: @escaping () -> Void, onSynonymTap: @escaping () -> Void, onTranslationTap: @escaping () -> Void, onSettingsTap: (() -> Void)? = nil, selectedButtonType: Binding<ToolbarButtonType>) {
        self.onExplanationTap = onExplanationTap
        self.onSynonymTap = onSynonymTap
        self.onTranslationTap = onTranslationTap
        self.onExampleTap = nil
        self.onSettingsTap = onSettingsTap
        self._selectedButtonType = selectedButtonType
        self.isVerbenMode = false
    }
    
    private func updateSelectedButton(_ newValue: ToolbarButtonType) {
        selectedButton = newValue
        selectedButtonType = newValue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            
            // Grouped action buttons
            if isVerbenMode {
                // VERBEN mode: Translation and Example only
                HStack(spacing: 0) {
                    // Translation button (first)
                    Button(action: {
                        updateSelectedButton(.translation)
                        onTranslationTap()
                    }) {
                        Image(systemName: ToolbarButtonType.translation.icon)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(selectedButton == .translation ? ToolbarButtonType.translation.color : .primary)
                            .frame(width: 44, height: 44)
                            .animation(.easeInOut(duration: 0.2), value: selectedButton)
                    }
                    .buttonStyle(GroupedToolbarButtonStyle(
                        isSelected: selectedButton == .translation,
                        accentColor: ToolbarButtonType.translation.color,
                        position: .leading
                    ))
                    .accessibilityLabel("Übersetzung")
                    .accessibilityHint("Zeigt Übersetzungen an")
                    .accessibilityAddTraits(selectedButton == .translation ? .isSelected : [])
                    
                    // Divider
                    Rectangle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 0.5, height: 24)
                    
                    // Example button (second)
                    Button(action: {
                        updateSelectedButton(.example)
                        onExampleTap?()
                    }) {
                        Image(systemName: ToolbarButtonType.example.icon)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(selectedButton == .example ? ToolbarButtonType.example.color : .primary)
                            .frame(width: 44, height: 44)
                            .animation(.easeInOut(duration: 0.2), value: selectedButton)
                    }
                    .buttonStyle(GroupedToolbarButtonStyle(
                        isSelected: selectedButton == .example,
                        accentColor: ToolbarButtonType.example.color,
                        position: .trailing
                    ))
                    .accessibilityLabel(Localizable.string(Localizable.practiseWithExample))
                    .accessibilityHint("Zeigt Beispiele an")
                    .accessibilityAddTraits(selectedButton == .example ? .isSelected : [])
                }
                .frame(height: 44)
                .background(LiquidGlassToolbarCapsule())
            } else {
                // Regular mode: Translation, Explanation, Synonym
                HStack(spacing: 0) {
                    // Translation button (first)
                    Button(action: {
                        updateSelectedButton(.translation)
                        onTranslationTap()
                    }) {
                        Image(systemName: ToolbarButtonType.translation.icon)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(selectedButton == .translation ? ToolbarButtonType.translation.color : .primary)
                            .frame(width: 44, height: 44)
                            .animation(.easeInOut(duration: 0.2), value: selectedButton)
                    }
                    .buttonStyle(GroupedToolbarButtonStyle(
                        isSelected: selectedButton == .translation,
                        accentColor: ToolbarButtonType.translation.color,
                        position: .leading
                    ))
                    .accessibilityLabel("Übersetzung")
                    .accessibilityHint("Zeigt Übersetzungen an")
                    .accessibilityAddTraits(selectedButton == .translation ? .isSelected : [])
                    
                    // Divider
                    Rectangle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 0.5, height: 24)
                    
                    // Explanation button (second)
                    Button(action: {
                        updateSelectedButton(.explanation)
                        onExplanationTap()
                    }) {
                        Image(systemName: ToolbarButtonType.explanation.icon)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(selectedButton == .explanation ? ToolbarButtonType.explanation.color : .primary)
                            .frame(width: 44, height: 44)
                            .animation(.easeInOut(duration: 0.2), value: selectedButton)
                    }
                    .buttonStyle(GroupedToolbarButtonStyle(
                        isSelected: selectedButton == .explanation,
                        accentColor: ToolbarButtonType.explanation.color,
                        position: .middle
                    ))
                    .accessibilityLabel("Erklärung")
                    .accessibilityHint("Zeigt Erklärungen an")
                    .accessibilityAddTraits(selectedButton == .explanation ? .isSelected : [])
                    
                    // Divider
                    Rectangle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 0.5, height: 24)
                    
                    // Synonym button (third)
                    Button(action: {
                        updateSelectedButton(.synonym)
                        onSynonymTap()
                    }) {
                        Image(systemName: ToolbarButtonType.synonym.icon)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(selectedButton == .synonym ? ToolbarButtonType.synonym.color : .primary)
                            .frame(width: 44, height: 44)
                            .animation(.easeInOut(duration: 0.2), value: selectedButton)
                    }
                    .buttonStyle(GroupedToolbarButtonStyle(
                        isSelected: selectedButton == .synonym,
                        accentColor: ToolbarButtonType.synonym.color,
                        position: .trailing
                    ))
                    .accessibilityLabel("Synonym")
                    .accessibilityHint("Zeigt Synonyme an")
                    .accessibilityAddTraits(selectedButton == .synonym ? .isSelected : [])
                }
                .frame(height: 44)
                .background(LiquidGlassToolbarCapsule())
            }
            
            Spacer()
        }
        .onChange(of: selectedButtonType) { oldValue, newValue in
            selectedButton = newValue
        }
    }
}

/// Shared chrome for segmented toolbar controls (word-list mode switcher, translation keyboard accessory, etc.).
struct LiquidGlassToolbarCapsule: View {
    var body: some View {
        Capsule()
            .fill(.regularMaterial)
            .overlay {
                Capsule()
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
                Capsule()
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

#Preview {
    GroupedToolbar(
        onExplanationTap: {},
        onSynonymTap: {},
        onTranslationTap: {},
        onSettingsTap: {},
        selectedButtonType: .constant(.translation)
    )
    .padding()
    .background(Color("AppGreenLight"))
}

