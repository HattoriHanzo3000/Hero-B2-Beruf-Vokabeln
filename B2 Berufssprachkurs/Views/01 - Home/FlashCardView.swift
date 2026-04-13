//
//  FlashCardView.swift
//  B2 Berufssprachkurs
//
//  Reusable flip-card UI component for study content.
//  Created: 24.03.26.
//

import SwiftUI

// MARK: - Component

struct FlashCardView: View {
    // MARK: Inputs

    let frontText: String
    let backText: String
    let cardColor: Color
    let cardId: String?

    // MARK: State

    @State private var isFlipped = false
    
    init(frontText: String, backText: String, cardColor: Color, cardId: String? = nil) {
        self.frontText = frontText
        self.backText = backText
        self.cardColor = cardColor
        self.cardId = cardId
    }
    
    private let grayColor = Color(.systemGray5)
    
    // MARK: View Layout

    var body: some View {
        ZStack {
            frontCard
                .opacity(isFlipped ? 0 : 1)
                .animation(nil, value: isFlipped)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            backCard
                .opacity(isFlipped ? 1 : 0)
                .animation(nil, value: isFlipped)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: cardId) { _, _ in
            isFlipped = false
        }
        .id(cardId)
    }
    
    // MARK: Card Faces

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
                        lineWidth: 0.8
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                cardColor.opacity(0.3),
                                cardColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
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
            .overlay {
                Text(frontText)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
            .transaction { transaction in
                transaction.animation = nil
            }
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
                        lineWidth: 0.8
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                grayColor.opacity(0.3),
                                grayColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
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
            .overlay {
                Text(backText)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

// MARK: - Preview

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

