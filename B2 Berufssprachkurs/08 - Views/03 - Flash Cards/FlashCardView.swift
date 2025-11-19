//
//  FlashCardView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct FlashCardView: View {
    let frontText: String
    let backText: String
    let cardColor: Color
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            if isFlipped {
                backCard
            } else {
                frontCard
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }
    
    private var frontCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                cardColor.opacity(0.1),
                                cardColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                Text(frontText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
    }
    
    private var backCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                cardColor.opacity(0.1),
                                cardColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                Text(backText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    }
}

#Preview {
    VStack {
        FlashCardView(
            frontText: "Synonym Beispiel",
            backText: "Das deutsche Wort",
            cardColor: .orange
        )
        .padding()
    }
}

