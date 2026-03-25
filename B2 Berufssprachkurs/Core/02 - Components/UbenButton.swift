//
//  UbenButton.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct UbenButton: View {
    let action: () -> Void
    let accentColor: Color
    let buttonText: String
    
    var body: some View {
        Button(action: action) {
            Text(buttonText)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LiquidGlass)
                .padding(.bottom, 12)
        }
        .buttonStyle(UbenButtonStyle())
    }
    
    private var LiquidGlass: some View {
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
    }
}

struct UbenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    VStack {
        Spacer()
        UbenButton(action: {}, accentColor: Color("AppGreen"), buttonText: "Practice with Synonym")
    }
    .background(Color("AppGreenLight"))
}

