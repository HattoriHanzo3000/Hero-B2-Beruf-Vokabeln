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
    
    var message: String {
        switch self {
        case .explanation: return "Erklärung"
        case .synonym: return "Synonym"
        case .translation: return "Übersetzung"
        }
    }
    
    var color: Color {
        switch self {
        case .explanation: return Color("AppOrange")
        case .synonym: return Color("AppGreen")
        case .translation: return Color("AppBlue")
        }
    }
    
    var buttonText: String {
        switch self {
        case .explanation: return "MIT ERKLÄRUNG ÜBEN"
        case .synonym: return "MIT SYNONYM ÜBEN"
        case .translation: return "MIT ÜBERSETZUNG ÜBEN"
        }
    }
}

struct GroupedToolbar: View {
    let onExplanationTap: () -> Void
    let onSynonymTap: () -> Void
    let onTranslationTap: () -> Void
    let onCheckmarkTap: () -> Void
    let onSettingsTap: () -> Void
    let isCheckmarkSelected: Bool
    @Binding var selectedButtonType: ToolbarButtonType
    
    @State private var selectedButton: ToolbarButtonType = .explanation
    
    init(onExplanationTap: @escaping () -> Void, onSynonymTap: @escaping () -> Void, onTranslationTap: @escaping () -> Void, onCheckmarkTap: @escaping () -> Void, onSettingsTap: @escaping () -> Void, isCheckmarkSelected: Bool, selectedButtonType: Binding<ToolbarButtonType>) {
        self.onExplanationTap = onExplanationTap
        self.onSynonymTap = onSynonymTap
        self.onTranslationTap = onTranslationTap
        self.onCheckmarkTap = onCheckmarkTap
        self.onSettingsTap = onSettingsTap
        self.isCheckmarkSelected = isCheckmarkSelected
        self._selectedButtonType = selectedButtonType
    }
    
    private func updateSelectedButton(_ newValue: ToolbarButtonType) {
        selectedButton = newValue
        selectedButtonType = newValue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark button
            Button(action: {
                onCheckmarkTap()
            }) {
                Image(systemName: "checkmark")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isCheckmarkSelected ? Color("AppGreen") : .primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(CircularLiquidGlassButtonStyle(isSelected: false, accentColor: Color("AppGreen")))
            .accessibilityLabel("Checkmark")
            .accessibilityHint("Markiert als erledigt")
            .accessibilityAddTraits(isCheckmarkSelected ? .isSelected : [])
            
            Spacer()
            
            // Grouped action buttons (explanation, synonym, translation)
            HStack(spacing: 0) {
                // Explanation button
                Button(action: {
                    updateSelectedButton(.explanation)
                    onExplanationTap()
                }) {
                    Image(systemName: "info")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedButton == .explanation ? ToolbarButtonType.explanation.color : .primary)
                        .frame(width: 44, height: 44)
                        .animation(.easeInOut(duration: 0.2), value: selectedButton)
                }
                .buttonStyle(GroupedToolbarButtonStyle(
                    isSelected: selectedButton == .explanation,
                    accentColor: ToolbarButtonType.explanation.color,
                    position: .leading
                ))
                .accessibilityLabel("Erklärung")
                .accessibilityHint("Zeigt Erklärungen an")
                .accessibilityAddTraits(selectedButton == .explanation ? .isSelected : [])
                
                // Divider
                Rectangle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 0.5, height: 24)
                
                // Synonym button
                Button(action: {
                    updateSelectedButton(.synonym)
                    onSynonymTap()
                }) {
                    Image(systemName: "figure.2")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedButton == .synonym ? ToolbarButtonType.synonym.color : .primary)
                        .frame(width: 44, height: 44)
                        .animation(.easeInOut(duration: 0.2), value: selectedButton)
                }
                .buttonStyle(GroupedToolbarButtonStyle(
                    isSelected: selectedButton == .synonym,
                    accentColor: ToolbarButtonType.synonym.color,
                    position: .middle
                ))
                .accessibilityLabel("Synonym")
                .accessibilityHint("Zeigt Synonyme an")
                .accessibilityAddTraits(selectedButton == .synonym ? .isSelected : [])
                
                // Divider
                Rectangle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 0.5, height: 24)
                
                // Translation button
                Button(action: {
                    updateSelectedButton(.translation)
                    onTranslationTap()
                }) {
                    Image(systemName: "globe")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedButton == .translation ? ToolbarButtonType.translation.color : .primary)
                        .frame(width: 44, height: 44)
                        .animation(.easeInOut(duration: 0.2), value: selectedButton)
                }
                .buttonStyle(GroupedToolbarButtonStyle(
                    isSelected: selectedButton == .translation,
                    accentColor: ToolbarButtonType.translation.color,
                    position: .trailing
                ))
                .accessibilityLabel("Übersetzung")
                .accessibilityHint("Zeigt Übersetzungen an")
                .accessibilityAddTraits(selectedButton == .translation ? .isSelected : [])
            }
            .frame(height: 44)
            .background(liquidGlassCapsule)
            
            Spacer()
            
            // Settings button
            Button(action: {
                onSettingsTap()
            }) {
                Image(systemName: "gearshape")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(CircularLiquidGlassButtonStyle(isSelected: false, accentColor: .secondary))
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens settings")
        }
        .onChange(of: selectedButtonType) { oldValue, newValue in
            selectedButton = newValue
        }
    }
    
    private var liquidGlassCapsule: some View {
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
        onCheckmarkTap: {},
        onSettingsTap: {},
        isCheckmarkSelected: false,
        selectedButtonType: .constant(.explanation)
    )
    .padding()
    .background(Color("AppGreenLight"))
}

