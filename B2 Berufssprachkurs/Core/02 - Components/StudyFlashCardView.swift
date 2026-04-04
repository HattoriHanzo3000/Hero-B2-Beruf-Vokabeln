//
//  StudyFlashCardView.swift
//  B2 Berufssprachkurs
//

import SwiftUI

struct StudyFlashCardView: View {
    let studyItem: StudyItem
    @Binding var currentContentType: StudyCardContentType
    let cardColor: Color
    let cardId: String?
    let initialFlipped: Bool
    @ObservedObject var dataService: DataService
    @Binding var buttonFeedback: StudyButtonFeedback?
    let onSwipeCorrect: (() -> Void)?
    let onSwipeWrong: (() -> Void)?

    @State private var showsFront = true
    @State private var halfAngle: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var thresholdReached = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        studyItem: StudyItem,
        currentContentType: Binding<StudyCardContentType>,
        cardColor: Color,
        cardId: String? = nil,
        initialFlipped: Bool = false,
        dataService: DataService,
        buttonFeedback: Binding<StudyButtonFeedback?>,
        onSwipeCorrect: (() -> Void)? = nil,
        onSwipeWrong: (() -> Void)? = nil
    ) {
        self.studyItem = studyItem
        self._currentContentType = currentContentType
        self.cardColor = cardColor
        self.cardId = cardId
        self.initialFlipped = initialFlipped
        self.dataService = dataService
        self._buttonFeedback = buttonFeedback
        self.onSwipeCorrect = onSwipeCorrect
        self.onSwipeWrong = onSwipeWrong
    }

    private let grayColor = Color(.systemGray5)
    private let swipeThreshold: CGFloat = 120

    private var frontText: String {
        if studyItem.isVerbenSection {
            if currentContentType == .translation {
                if let translation = studyItem.translation, !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return translation
                }
                return ""
            }
            if currentContentType == .explanation {
                if let explanation = studyItem.explanation, !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return explanation
                }
                return ""
            }
            if let quiz = studyItem.quiz, !quiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return quiz
            }
            if let explanation = studyItem.explanation, !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return explanation
            }
            return studyItem.example ?? ""
        }

        switch currentContentType {
        case .synonym:
            return studyItem.synonym ?? ""
        case .explanation:
            return studyItem.explanation ?? ""
        case .translation:
            return studyItem.translation ?? ""
        }
    }

    private var shouldShowPlaceholder: Bool {
        if studyItem.isVerbenSection {
            if currentContentType == .translation {
                let translation = studyItem.translation ?? ""
                return translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if currentContentType == .explanation {
                let explanation = studyItem.explanation ?? ""
                return explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        }

        if currentContentType == .translation {
            let translation = studyItem.translation ?? ""
            return translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if currentContentType == .explanation {
            let explanation = studyItem.explanation ?? ""
            return explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if currentContentType == .synonym {
            let synonym = studyItem.synonym ?? ""
            return synonym.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return false
    }

    private var flashcardEmptyStateMessage: String {
        switch currentContentType {
        case .translation:
            return Localizable.string(Localizable.flashcardNoTranslationYet)
        case .explanation:
            return Localizable.string(Localizable.flashcardNoExplanationYet)
        case .synonym:
            return Localizable.string(Localizable.flashcardNoSynonymYet)
        }
    }

    private func performFlip() {
        if reduceMotion {
            showsFront.toggle()
            halfAngle = showsFront ? 0 : 180
            return
        }
        let target: Double = showsFront ? 180 : 0
        withAnimation(.easeIn(duration: 0.25)) {
            halfAngle = 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showsFront.toggle()
            withAnimation(.easeOut(duration: 0.25)) {
                halfAngle = target
            }
        }
    }

    var body: some View {
        ZStack {
            frontCard
                .opacity(showsFront ? 1 : 0)
                .accessibilityHidden(!showsFront)

            backCard
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsFront ? 0 : 1)
                .accessibilityHidden(showsFront)
        }
        .rotation3DEffect(.degrees(halfAngle), axis: (x: 0, y: 1, z: 0))
        .accessibilityElement(children: .contain)
        .accessibilityValue(showsFront ? Localizable.string(Localizable.studyFlashcardSideFrontA11y) : Localizable.string(Localizable.studyFlashcardSideBackA11y))
        .offset(dragOffset)
        .rotationEffect(.degrees(reduceMotion ? 0 : dragRotation))
        .opacity(1 - min(abs(dragOffset.width) / 600.0, 0.3))
        .overlay {
            if abs(dragOffset.width) > 50 {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        dragOffset.width > 0 ?
                            Color.green.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3)) :
                            Color.red.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3))
                    )
                    .allowsHitTesting(false)
            } else if let feedback = buttonFeedback {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        feedback == .correct ?
                            Color.green.opacity(0.3) :
                            Color.red.opacity(0.3)
                    )
                    .allowsHitTesting(false)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    let horizontalDrag = value.translation.width
                    dragOffset = CGSize(width: horizontalDrag, height: value.translation.height * 0.3)

                    if !reduceMotion {
                        dragRotation = Double(horizontalDrag / 20)
                    }

                    if abs(horizontalDrag) > swipeThreshold && !thresholdReached {
                        HapticManager.shared.mediumImpact()
                        thresholdReached = true
                    } else if abs(horizontalDrag) <= swipeThreshold && thresholdReached {
                        thresholdReached = false
                    }
                }
                .onEnded { value in
                    let horizontalDrag = value.translation.width

                    if horizontalDrag > swipeThreshold {
                        HapticManager.shared.mediumImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = CGSize(width: 1000, height: 0)
                            dragRotation = 30
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSwipeCorrect?()
                        }
                    } else if horizontalDrag < -swipeThreshold {
                        HapticManager.shared.lightImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = CGSize(width: -1000, height: 0)
                            dragRotation = -30
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onSwipeWrong?()
                        }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = .zero
                            dragRotation = 0
                        }
                        thresholdReached = false
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if dragOffset == .zero {
                        performFlip()
                    }
                }
        )
        .onChange(of: cardId) { _, _ in
            showsFront = !initialFlipped
            halfAngle = initialFlipped ? 180 : 0
            dragOffset = .zero
            dragRotation = 0
            thresholdReached = false
        }
        .onChange(of: studyItem.wordId) { _, _ in
            if studyItem.isVerbenSection {
                if currentContentType == .explanation {
                    let explanation = studyItem.explanation ?? ""
                    if explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       let translation = studyItem.translation,
                       !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        currentContentType = .translation
                    }
                }
            } else {
                var isAvailable = false
                switch currentContentType {
                case .explanation:
                    isAvailable = studyItem.explanation != nil
                case .translation:
                    isAvailable = true
                case .synonym:
                    isAvailable = studyItem.synonym != nil
                }

                if !isAvailable {
                    if studyItem.explanation != nil {
                        currentContentType = .explanation
                    } else if studyItem.translation != nil {
                        currentContentType = .translation
                    } else if studyItem.synonym != nil {
                        currentContentType = .synonym
                    } else {
                        currentContentType = .translation
                    }
                }
            }
        }
        .onChange(of: initialFlipped) { _, newValue in
            let target = !newValue
            if showsFront != target {
                performFlip()
            }
        }
        .onAppear {
            showsFront = !initialFlipped
            halfAngle = initialFlipped ? 180 : 0
        }
        .id(cardId)
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
                if shouldShowPlaceholder {
                    VStack(spacing: 12) {
                        Image(systemName: "pencil")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(flashcardEmptyStateMessage)
                            .font(.system(.body, design: .default))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityHidden(true)
                    .padding(.horizontal, 32)
                } else {
                    Text(frontText)
                        .font(.system(.title2, design: .default).weight(.regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .accessibilityLabel(
                String(
                    format: Localizable.string(Localizable.studyFlashcardFrontA11y),
                    shouldShowPlaceholder ? flashcardEmptyStateMessage : frontText
                )
            )
            .accessibilityHint(Localizable.string(Localizable.studyFlashcardFlipHintA11y))
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
                VStack(spacing: 16) {
                    if studyItem.isVerbenSection || studyItem.sectionId.hasPrefix("ADJEKTIVE_") {
                        Text(studyItem.germanWord)
                            .font(.system(.title2, design: .default).weight(.regular))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        if let example = studyItem.example, !example.isEmpty {
                            Text(example)
                                .font(.body)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text(studyItem.germanWord)
                            .font(.system(.title2, design: .default).weight(.regular))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        if let example = studyItem.example, !example.isEmpty {
                            Text(example)
                                .font(.body)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .accessibilityLabel(
                {
                    if let example = studyItem.example, !example.isEmpty {
                        return String(
                            format: Localizable.string(Localizable.studyFlashcardBackWithExampleA11y),
                            studyItem.germanWord,
                            example
                        )
                    }
                    return String(
                        format: Localizable.string(Localizable.studyFlashcardBackWordOnlyA11y),
                        studyItem.germanWord
                    )
                }()
            )
            .accessibilityHint(Localizable.string(Localizable.studyFlashcardFlipHintA11y))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(height: 400)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}
