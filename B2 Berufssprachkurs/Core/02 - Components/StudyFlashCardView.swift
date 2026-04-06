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
        StudyFlashCardContentResolver.frontText(for: studyItem, contentType: currentContentType)
    }

    private var shouldShowPlaceholder: Bool {
        StudyFlashCardContentResolver.shouldShowPlaceholder(for: studyItem, contentType: currentContentType)
    }

    private var flashcardEmptyStateMessage: String {
        StudyFlashCardContentResolver.emptyStateMessage(for: currentContentType)
    }

    private var frontAccessibilityText: String {
        shouldShowPlaceholder ? flashcardEmptyStateMessage : frontText
    }

    private var backAccessibilityText: String {
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

    private func resetCardState() {
        showsFront = !initialFlipped
        halfAngle = initialFlipped ? 180 : 0
        dragOffset = .zero
        dragRotation = 0
        thresholdReached = false
    }

    private func syncContentTypeForCurrentItem() {
        currentContentType = StudyFlashCardContentResolver.resolvedContentTypeOnWordChange(
            for: studyItem,
            current: currentContentType
        )
    }

    @ViewBuilder
    private var dragAndFeedbackOverlay: some View {
        if abs(dragOffset.width) > 50 {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    dragOffset.width > 0
                        ? Color.green.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3))
                        : Color.red.opacity(min(abs(dragOffset.width) / swipeThreshold * 0.3, 0.3))
                )
                .allowsHitTesting(false)
        } else if let feedback = buttonFeedback {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(feedback == .correct ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                .allowsHitTesting(false)
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
        .overlay { dragAndFeedbackOverlay }
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
            resetCardState()
        }
        .onChange(of: studyItem.wordId) { _, _ in
            syncContentTypeForCurrentItem()
        }
        .onChange(of: initialFlipped) { _, newValue in
            let target = !newValue
            if showsFront != target {
                performFlip()
            }
        }
        .onAppear {
            resetCardState()
            syncContentTypeForCurrentItem()
        }
        .id(cardId)
    }

    private var frontCard: some View {
        StudyFlashCardFaceView(tintColor: cardColor) {
            Group {
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
            .accessibilityLabel(String(
                format: Localizable.string(Localizable.studyFlashcardFrontA11y),
                frontAccessibilityText
            ))
            .accessibilityHint(Localizable.string(Localizable.studyFlashcardFlipHintA11y))
        }
    }

    private var backCard: some View {
        StudyFlashCardFaceView(tintColor: grayColor) {
            VStack(spacing: 16) {
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
            .padding(.horizontal, 32)
            .accessibilityLabel(backAccessibilityText)
            .accessibilityHint(Localizable.string(Localizable.studyFlashcardFlipHintA11y))
        }
    }
}
