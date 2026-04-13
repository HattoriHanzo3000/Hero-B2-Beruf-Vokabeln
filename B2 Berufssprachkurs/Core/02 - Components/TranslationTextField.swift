//
//  TranslationTextField.swift
//  B2 Berufssprachkurs
//
//  Multi-line UITextView (grows downward, fixed width) + UIKit UIToolbar as inputAccessoryView.
//

import SwiftUI
import UIKit

struct TranslationTextField: UIViewRepresentable {
    @Binding var text: String
    let wordId: String
    @Binding var focusedWordId: String?
    let placeholder: String
    let showsKeyboardAccessory: Bool

    @EnvironmentObject private var keyboardNav: WordListKeyboardNavBridge
    var keyboardNavBridge: WordListKeyboardNavBridge { keyboardNav }

    init(
        text: Binding<String>,
        wordId: String,
        focusedWordId: Binding<String?>,
        placeholder: String,
        showsKeyboardAccessory: Bool = true
    ) {
        self._text = text
        self.wordId = wordId
        self._focusedWordId = focusedWordId
        self.placeholder = placeholder
        self.showsKeyboardAccessory = showsKeyboardAccessory
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        TranslationTextFieldStyle.apply(to: tv)

        let ph = TranslationTextFieldStyle.makePlaceholderLabel(text: placeholder, font: TranslationTextFieldStyle.calloutFont)
        tv.addSubview(ph)
        let placeholderTrailing = ph.trailingAnchor.constraint(lessThanOrEqualTo: tv.trailingAnchor, constant: -TranslationFieldLayout.insetXCompact)
        NSLayoutConstraint.activate([
            ph.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: TranslationFieldLayout.insetXCompact),
            placeholderTrailing,
            ph.topAnchor.constraint(equalTo: tv.topAnchor, constant: TranslationFieldLayout.insetYTop),
        ])
        context.coordinator.placeholderLabel = ph
        context.coordinator.placeholderTrailingConstraint = placeholderTrailing

        context.coordinator.textView = tv
        if showsKeyboardAccessory {
            context.coordinator.installToolbarIfNeeded()
        }
        tv.inputAccessoryView = showsKeyboardAccessory ? context.coordinator.toolbar : nil
        context.coordinator.applyTextContainerInsets()

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self

        if uiView.font != TranslationTextFieldStyle.calloutFont {
            uiView.font = TranslationTextFieldStyle.calloutFont
        }
        context.coordinator.placeholderLabel?.font = uiView.font
        context.coordinator.placeholderLabel?.text = placeholder

        if uiView.text != text {
            context.coordinator.isApplyingTextFromBinding = true
            uiView.text = text
            context.coordinator.isApplyingTextFromBinding = false
        }
        context.coordinator.placeholderLabel?.isHidden = !(uiView.text ?? "").isEmpty
        context.coordinator.applyTextContainerInsets()
        if let phView = context.coordinator.placeholderLabel { uiView.bringSubviewToFront(phView) }

        if showsKeyboardAccessory {
            context.coordinator.installToolbarIfNeeded()
        }
        let expectedAccessory: UIView? = showsKeyboardAccessory ? context.coordinator.toolbar : nil
        if uiView.inputAccessoryView !== expectedAccessory {
            uiView.inputAccessoryView = expectedAccessory
            if uiView.isFirstResponder {
                uiView.reloadInputViews()
            }
        }

        if focusedWordId == wordId {
            if !uiView.isFirstResponder {
                context.coordinator.requestFirstResponderIfNeeded()
            }
        } else {
            context.coordinator.cancelFocusRetries()
            // Only resign when editing ends entirely. If another row is focused, that field steals first responder — don’t dismiss the keyboard between prev/next.
            if uiView.isFirstResponder, focusedWordId == nil {
                uiView.resignFirstResponder()
            }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let proposedWidth = proposal.width ?? UIScreen.main.bounds.width
        guard proposedWidth.isFinite, proposedWidth > 1 else { return nil }

        let parent = context.coordinator.parent
        let isRowActive = parent.focusedWordId == parent.wordId
        if !isRowActive {
            return CGSize(width: proposedWidth, height: 1)
        }

        let font = uiView.font ?? UIFont.preferredFont(forTextStyle: .callout)
        let horizontalInset = uiView.textContainerInset.left + uiView.textContainerInset.right
        let verticalInset = uiView.textContainerInset.top + uiView.textContainerInset.bottom
        let textWidth = max(1, proposedWidth - horizontalInset)
        let rawText = String(uiView.text)
        let measureText: String = rawText.isEmpty ? " " : rawText
        let rect = measureText.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let minLine = ceil(font.lineHeight)
        let textHeight = max(minLine, ceil(rect.height))
        let totalHeight = textHeight + verticalInset
        return CGSize(width: proposedWidth, height: totalHeight)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TranslationTextField

        weak var textView: UITextView?
        var placeholderLabel: UILabel?
        var placeholderTrailingConstraint: NSLayoutConstraint?
        let toolbar = UIToolbar(frame: .zero)

        var keyboardAccessoryHost: UIHostingController<FloatingKeyboardAccessoryHostView>?
        let focusRetrier = TranslationFocusRetrier()

        var isApplyingTextFromBinding = false

        init(_ parent: TranslationTextField) {
            self.parent = parent
            super.init()
            toolbar.sizeToFit()
        }

        func applyTextContainerInsets() {
            guard let tv = textView else { return }
            let inset = TranslationFieldLayout.textContainerInsets
            if tv.textContainerInset != inset {
                tv.textContainerInset = inset
            }
            placeholderTrailingConstraint?.constant = -inset.right
        }

        func cancelFocusRetries() {
            focusRetrier.cancel()
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isApplyingTextFromBinding else { return }
            parent.text = textView.text ?? ""
            placeholderLabel?.isHidden = !(textView.text ?? "").isEmpty
            applyTextContainerInsets()
            textView.invalidateIntrinsicContentSize()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.focusedWordId = parent.wordId
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            placeholderLabel?.isHidden = !(textView.text ?? "").isEmpty
            applyTextContainerInsets()
        }
    }
}

extension TranslationTextField {
    /// For `HStack(alignment: .firstTextBaseline)` beside SwiftUI `.callout` lemma: top of view → first baseline of `.callout` text in the `UITextView`.
    static func rowFirstBaselineFromTopForBodyStyle() -> CGFloat {
        let font = TranslationTextFieldStyle.calloutFont
        return TranslationFieldLayout.insetYTop + font.lineHeight + font.descender
    }
}
