//
//  ActionButtonsContainer.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct ActionButtonsContainer: View {
    let onExplanationTap: () -> Void
    let onSynonymTap: () -> Void
    let onTranslationTap: () -> Void
    let onCheckmarkTap: () -> Void
    let onSettingsTap: () -> Void
    let isCheckmarkSelected: Bool
    @Binding var selectedButtonType: ToolbarButtonType
    
    var body: some View {
        GroupedToolbar(
            onExplanationTap: onExplanationTap,
            onSynonymTap: onSynonymTap,
            onTranslationTap: onTranslationTap,
            onCheckmarkTap: onCheckmarkTap,
            onSettingsTap: onSettingsTap,
            isCheckmarkSelected: isCheckmarkSelected,
            selectedButtonType: $selectedButtonType
        )
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(liquidGlassBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.4),
                        .white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.8
            )
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var liquidGlassBackground: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color("AppGreen").opacity(0.9),
                        Color("AppGreen").opacity(0.65),
                        Color("AppBlue").opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.20),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
    }
}

#Preview {
    ActionButtonsContainer(
        onExplanationTap: {},
        onSynonymTap: {},
        onTranslationTap: {},
        onCheckmarkTap: {},
        onSettingsTap: {},
        isCheckmarkSelected: false,
        selectedButtonType: .constant(.explanation)
    )
    .background(Color("AppGreenLight"))
}

