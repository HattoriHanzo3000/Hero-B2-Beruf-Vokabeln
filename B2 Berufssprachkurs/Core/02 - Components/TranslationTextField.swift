//
//  TranslationTextField.swift
//  B2 Berufssprachkurs
//
//  Multi-line UITextView (grows downward, fixed width) + UIKit UIToolbar as inputAccessoryView.
//

import SwiftUI
import UIKit

private enum TranslationFieldLayout {
    static let insetXCompact: CGFloat = 10
    /// Equal top/bottom so single-line `.subheadline` sits vertically centered in the field.
    static let insetYTop: CGFloat = 6
    static let insetYBottom: CGFloat = 6

    static var textContainerInsets: UIEdgeInsets {
        UIEdgeInsets(top: insetYTop, left: insetXCompact, bottom: insetYBottom, right: insetXCompact)
    }
}

struct TranslationTextField: UIViewRepresentable {
    @Binding var text: String
    let wordId: String
    @Binding var focusedWordId: String?
    let placeholder: String

    @EnvironmentObject private var keyboardNav: WordListKeyboardNavBridge

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        tv.font = font
        tv.adjustsFontForContentSizeCategory = true
        tv.textColor = .label
        tv.tintColor = .label
        tv.autocorrectionType = .yes
        tv.autocapitalizationType = .sentences
        tv.smartDashesType = .yes
        tv.smartQuotesType = .yes
        tv.returnKeyType = .default
        tv.isScrollEnabled = false
        tv.textAlignment = .natural
        tv.backgroundColor = UIColor.secondarySystemFill
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainerInset = TranslationFieldLayout.textContainerInsets
        tv.textContainer.widthTracksTextView = true
        tv.layer.cornerRadius = 8
        tv.layer.cornerCurve = .continuous
        tv.layer.borderWidth = 1.0 / UIScreen.main.scale
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.clipsToBounds = true

        let ph = UILabel()
        ph.text = placeholder
        ph.textColor = UIColor.placeholderText
        ph.font = font
        ph.numberOfLines = 0
        ph.textAlignment = .natural
        ph.isUserInteractionEnabled = false
        ph.translatesAutoresizingMaskIntoConstraints = false
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
        context.coordinator.installToolbarIfNeeded()
        tv.inputAccessoryView = context.coordinator.toolbar
        context.coordinator.applyTextContainerInsets()

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self

        if uiView.font != UIFont.preferredFont(forTextStyle: .subheadline) {
            uiView.font = UIFont.preferredFont(forTextStyle: .subheadline)
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

        if uiView.inputAccessoryView !== context.coordinator.toolbar {
            uiView.inputAccessoryView = context.coordinator.toolbar
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

        let font = uiView.font ?? UIFont.preferredFont(forTextStyle: .subheadline)
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

        private var keyboardAccessoryHost: UIHostingController<TranslationKeyboardNavAccessory>?

        var isApplyingTextFromBinding = false
        private var focusSession: UInt = 0
        private var scheduledFocusSession: UInt?

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
            focusSession &+= 1
            scheduledFocusSession = nil
        }

        func requestFirstResponderIfNeeded() {
            guard parent.focusedWordId == parent.wordId else { return }
            if scheduledFocusSession == focusSession { return }
            scheduledFocusSession = focusSession
            let session = focusSession
            let wid = parent.wordId
            for delay in [0.0, 0.05, 0.2, 0.45] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else { return }
                    guard session == self.focusSession else { return }
                    guard self.parent.focusedWordId == wid else { return }
                    guard let tv = self.textView, tv.window != nil else { return }
                    if !tv.isFirstResponder {
                        tv.becomeFirstResponder()
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                guard session == self.focusSession else { return }
                guard self.parent.focusedWordId == wid else { return }
                if self.textView?.isFirstResponder != true {
                    self.scheduledFocusSession = nil
                }
            }
        }

        func installToolbarIfNeeded() {
            guard keyboardAccessoryHost == nil else { return }

            let root = TranslationKeyboardNavAccessory(
                keyboardNav: parent.keyboardNav,
                onPrevious: { [weak self] in
                    guard let self else { return }
                    HapticManager.shared.lightImpact()
                    self.parent.keyboardNav.onPrevious()
                },
                onNext: { [weak self] in
                    guard let self else { return }
                    HapticManager.shared.lightImpact()
                    self.parent.keyboardNav.onNext()
                },
                onDone: { [weak self] in
                    guard let self else { return }
                    HapticManager.shared.lightImpact()
                    self.parent.keyboardNav.onDismiss()
                }
            )

            let host = UIHostingController(rootView: root)
            host.view.backgroundColor = .clear
            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.safeAreaRegions = []
            if #available(iOS 16.0, *) {
                host.sizingOptions = [.intrinsicContentSize]
            }
            NSLayoutConstraint.activate([
                host.view.heightAnchor.constraint(equalToConstant: 44),
            ])

            let group = UIBarButtonItem(customView: host.view)
            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbar.items = [flex, group]
            keyboardAccessoryHost = host
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
    /// For `HStack(alignment: .firstTextBaseline)` beside SwiftUI `.body` lemma: top of view → first baseline of `.subheadline` text in the `UITextView`.
    static func rowFirstBaselineFromTopForBodyStyle() -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        return TranslationFieldLayout.insetYTop + font.lineHeight + font.descender
    }
}
