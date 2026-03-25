//
//  WordsHeaderView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct WordsHeaderView: View {
    let lectionTitle: String
    let sectionTitle: String
    let lectionNumber: String
    let sectionLetter: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Custom back button at the top with liquid glass design
            Button(action: {
                HapticManager.shared.lightImpact()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(CircularLiquidGlassButtonStyle(isSelected: false, accentColor: .secondary))
            
            // Row 1: Lection title with number
            HStack(spacing: 12) {
                // Lection number (only show if not empty)
                if !lectionNumber.isEmpty {
                    Text(lectionNumber)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text(lectionTitle)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Row 2: Section title with letter
            HStack(spacing: 8) {
                // Section letter (only show if not empty)
                if !sectionLetter.isEmpty {
                    Text(sectionLetter)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Text(sectionTitle)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
    WordsHeaderView(
        lectionTitle: "Lektion 1",
        sectionTitle: "Abschnitt A",
        lectionNumber: "1",
        sectionLetter: "A"
    )
    .background(Color("AppGreenLight"))
}

