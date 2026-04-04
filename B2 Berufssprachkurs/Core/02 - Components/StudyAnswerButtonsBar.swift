//
//  StudyAnswerButtonsBar.swift
//  B2 Berufssprachkurs
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StudyAnswerButtonsBar: View {
    @Binding var buttonFeedback: StudyButtonFeedback?
    let onWrong: () -> Void
    let onCorrect: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            Button(action: {
                HapticManager.shared.lightImpact()
                buttonFeedback = .wrong
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onWrong()
                    buttonFeedback = nil
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(.title3, design: .default).weight(.semibold))
                    .foregroundColor(.red)
                    .frame(width: 64, height: 64)
                    .background(liquidGlassCircle)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(Localizable.string(Localizable.studyMarkWrongA11y))
            .accessibilityHint(Localizable.string(Localizable.studyMarkWrongHintA11y))

            Button(action: {
                HapticManager.shared.mediumImpact()
                buttonFeedback = .correct
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onCorrect()
                    buttonFeedback = nil
                }
            }) {
                Image(systemName: "checkmark")
                    .font(.system(.title3, design: .default).weight(.semibold))
                    .foregroundColor(.green)
                    .frame(width: 64, height: 64)
                    .background(liquidGlassCircle)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(Localizable.string(Localizable.studyMarkCorrectA11y))
            .accessibilityHint(Localizable.string(Localizable.studyMarkCorrectHintA11y))
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
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
