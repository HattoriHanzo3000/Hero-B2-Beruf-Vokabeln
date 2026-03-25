//
//  UbenButtonGroup.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct UbenButtonGroup: View {
    @Binding var selectedButtonType: ToolbarButtonType
    let onButtonTap: (ToolbarButtonType) -> Void
    
    @Namespace private var buttonNamespace
    @State private var pendingActivation: ToolbarButtonType? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Translation button (left)
            UbenGroupButton(
                type: .translation,
                isSelected: selectedButtonType == .translation,
                position: getButtonPosition(for: .translation),
                namespace: buttonNamespace,
                isPendingActivation: pendingActivation == .translation,
                onTap: {
                    if selectedButtonType == .translation && pendingActivation == .translation {
                        // Second tap: activate
                        HapticManager.shared.mediumImpact()
                        pendingActivation = nil
                        onButtonTap(.translation)
                    } else {
                        // First tap: change selection
                        HapticManager.shared.selection()
                        pendingActivation = .translation
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedButtonType = .translation
                        }
                    }
                }
            )
            
            // Explanation button (middle)
            UbenGroupButton(
                type: .explanation,
                isSelected: selectedButtonType == .explanation,
                position: getButtonPosition(for: .explanation),
                namespace: buttonNamespace,
                isPendingActivation: pendingActivation == .explanation,
                onTap: {
                    if selectedButtonType == .explanation && pendingActivation == .explanation {
                        // Second tap: activate
                        HapticManager.shared.mediumImpact()
                        pendingActivation = nil
                        onButtonTap(.explanation)
                    } else {
                        // First tap: change selection
                        HapticManager.shared.selection()
                        pendingActivation = .explanation
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedButtonType = .explanation
                        }
                    }
                }
            )
            
            // Synonym button (right)
            UbenGroupButton(
                type: .synonym,
                isSelected: selectedButtonType == .synonym,
                position: getButtonPosition(for: .synonym),
                namespace: buttonNamespace,
                isPendingActivation: pendingActivation == .synonym,
                onTap: {
                    if selectedButtonType == .synonym && pendingActivation == .synonym {
                        // Second tap: activate
                        HapticManager.shared.mediumImpact()
                        pendingActivation = nil
                        onButtonTap(.synonym)
                    } else {
                        // First tap: change selection
                        HapticManager.shared.selection()
                        pendingActivation = .synonym
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedButtonType = .synonym
                        }
                    }
                }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .onAppear {
            // Initialize pending activation to the default selected button
            if pendingActivation == nil {
                pendingActivation = selectedButtonType
            }
        }
        .onChange(of: selectedButtonType) { oldValue, newValue in
            // Set pending activation to the newly selected button
            pendingActivation = newValue
        }
    }
    
    private func getButtonPosition(for type: ToolbarButtonType) -> ButtonPosition {
        switch selectedButtonType {
        case .translation:
            return type == .translation ? .expanded : (type == .explanation ? .middle : .right)
        case .explanation:
            return type == .explanation ? .expanded : (type == .translation ? .left : .right)
        case .synonym:
            return type == .synonym ? .expanded : (type == .translation ? .left : .middle)
        case .example:
            return .right // Not used in regular mode
        }
    }
}

struct UbenButtonGroupVerben: View {
    @Binding var selectedButtonType: ToolbarButtonType
    let onButtonTap: (ToolbarButtonType) -> Void
    
    @Namespace private var buttonNamespace
    @State private var pendingActivation: ToolbarButtonType? = nil
    
    init(selectedButtonType: Binding<ToolbarButtonType>, onButtonTap: @escaping (ToolbarButtonType) -> Void) {
        self._selectedButtonType = selectedButtonType
        self.onButtonTap = onButtonTap
        // Initialize pendingActivation to the default selected button
        _pendingActivation = State(initialValue: selectedButtonType.wrappedValue)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Translation button (left)
            UbenGroupButton(
                type: .translation,
                isSelected: selectedButtonType == .translation,
                position: getButtonPosition(for: .translation),
                namespace: buttonNamespace,
                isPendingActivation: pendingActivation == .translation,
                onTap: {
                    if selectedButtonType == .translation && pendingActivation == .translation {
                        // Second tap: activate
                        HapticManager.shared.mediumImpact()
                        pendingActivation = nil
                        onButtonTap(.translation)
                    } else {
                        // First tap: change selection
                        HapticManager.shared.selection()
                        pendingActivation = .translation
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedButtonType = .translation
                        }
                    }
                }
            )
            
            // Example button (right)
            UbenGroupButton(
                type: .example,
                isSelected: selectedButtonType == .example,
                position: getButtonPosition(for: .example),
                namespace: buttonNamespace,
                isPendingActivation: pendingActivation == .example,
                onTap: {
                    if selectedButtonType == .example && pendingActivation == .example {
                        // Second tap: activate
                        HapticManager.shared.mediumImpact()
                        pendingActivation = nil
                        onButtonTap(.example)
                    } else {
                        // First tap: change selection
                        HapticManager.shared.selection()
                        pendingActivation = .example
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedButtonType = .example
                        }
                    }
                }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .onAppear {
            // Initialize pending activation to the default selected button
            if pendingActivation == nil {
                pendingActivation = selectedButtonType
            }
        }
        .onChange(of: selectedButtonType) { oldValue, newValue in
            // Set pending activation to the newly selected button
            pendingActivation = newValue
        }
    }
    
    private func getButtonPosition(for type: ToolbarButtonType) -> ButtonPosition {
        switch selectedButtonType {
        case .translation:
            return type == .translation ? .expanded : .right
        case .example:
            return type == .example ? .expanded : .left
        default:
            return .left
        }
    }
}

enum ButtonPosition {
    case left
    case middle
    case right
    case expanded
}

struct UbenGroupButton: View {
    let type: ToolbarButtonType
    let isSelected: Bool
    let position: ButtonPosition
    let namespace: Namespace.ID
    let isPendingActivation: Bool
    let onTap: () -> Void
    
    private var isExpanded: Bool {
        position == .expanded
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if isExpanded {
                    // Show full text when expanded
                    Text(type.buttonText)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    // Show only icon when collapsed
                    Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .frame(width: isExpanded ? nil : 50)
            .frame(maxWidth: isExpanded ? .infinity : nil)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(UbenGroupButtonStyle(
            isSelected: isSelected,
            accentColor: type.color,
            isExpanded: isExpanded
        ))
        .matchedGeometryEffect(id: "button-\(type)", in: namespace)
    }
}

struct UbenGroupButtonStyle: ButtonStyle {
    let isSelected: Bool
    let accentColor: Color
    let isExpanded: Bool
    
    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if isExpanded {
            configuration.label
                .background(liquidGlassBackground)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        } else {
            configuration.label
                .background(liquidGlassBackground)
                .clipShape(Circle())
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
    
    private var liquidGlassBackground: some View {
        Group {
            if isExpanded {
                // Expanded button: capsule shape
                Capsule()
                    .fill(.regularMaterial)
                    .overlay {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.4),
                                        accentColor.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.5),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .overlay {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                accentColor.opacity(0.5),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            } else {
                // Collapsed button: circle shape
                Circle()
                    .fill(.regularMaterial)
                    .overlay {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.3),
                                        accentColor.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
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
                                lineWidth: 0.5
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
                    .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        UbenButtonGroup(
            selectedButtonType: .constant(.translation),
            onButtonTap: { _ in }
        )
    }
    .background(Color("AppGreenLight"))
}

