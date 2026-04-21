//
//  AttributedString+B2WordListDetail.swift
//  B2 Berufssprachkurs
//
//  Typography for word-list detail lines (label + value).
//

import Foundation
import SwiftUI

extension AttributedString {
    static func b2_wordListDetailLine(
        label: String,
        value: String,
        labelFont: Font = .caption.weight(.semibold),
        valueFont: Font = .caption,
        labelColor: Color = .secondary,
        valueColor: Color = .primary
    ) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        if let labelRange = fullText.range(of: label) {
            fullText[labelRange].font = labelFont
            fullText[labelRange].foregroundColor = labelColor
        }
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
            fullText[valueRange].foregroundColor = valueColor
        }
        return fullText
    }
}
