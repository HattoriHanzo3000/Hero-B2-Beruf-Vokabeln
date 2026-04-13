//
//  TranslationTextFieldStyle.swift
//  B2 Berufssprachkurs
//

import UIKit

enum TranslationFieldLayout {
    static let insetXCompact: CGFloat = 10
    /// Equal top/bottom so single-line `.callout` sits vertically centered in the field.
    static let insetYTop: CGFloat = 6
    static let insetYBottom: CGFloat = 6

    static var textContainerInsets: UIEdgeInsets {
        UIEdgeInsets(top: insetYTop, left: insetXCompact, bottom: insetYBottom, right: insetXCompact)
    }
}

enum TranslationTextFieldStyle {
    static var calloutFont: UIFont {
        UIFont.preferredFont(forTextStyle: .callout)
    }

    static func apply(to textView: UITextView) {
        textView.font = calloutFont
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .label
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .none
        textView.smartDashesType = .yes
        textView.smartQuotesType = .yes
        textView.returnKeyType = .default
        textView.isScrollEnabled = false
        textView.textAlignment = .natural
        textView.backgroundColor = .secondarySystemFill
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = TranslationFieldLayout.textContainerInsets
        textView.textContainer.widthTracksTextView = true
        textView.layer.cornerRadius = 8
        textView.layer.cornerCurve = .continuous
        textView.layer.borderWidth = 1.0 / UIScreen.main.scale
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.clipsToBounds = true
    }

    static func makePlaceholderLabel(text: String, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .placeholderText
        label.font = font
        label.numberOfLines = 0
        label.textAlignment = .natural
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
