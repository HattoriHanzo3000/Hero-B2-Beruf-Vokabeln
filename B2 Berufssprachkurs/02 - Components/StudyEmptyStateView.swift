//
//  StudyEmptyStateView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct StudyEmptyStateView: View {
    let title: String
    let message: String
    let iconName: String
    let modeTitle: String
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color("AppGreenLight")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    // Back button with liquid glass style
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        onBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(liquidGlassCircle)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Back")
                    .accessibilityHint("Return to previous screen")
                    
                    Spacer()
                    
                    // Title
                    Text(modeTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    // Empty space to balance the layout
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer()
                
                // Empty state content
                VStack(spacing: 20) {
                    Image(systemName: iconName)
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
            }
        }
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
    StudyEmptyStateView(
        title: "Keine Wörter ausgewählt",
        message: "Wähle die Wörter mit dem Häkchen aus",
        iconName: "checkmark.circle",
        modeTitle: "Übersetzung",
        onBack: {}
    )
}

