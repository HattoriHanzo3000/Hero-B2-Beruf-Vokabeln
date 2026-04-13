//
//  PDFGenerationWordLayout.swift
//  B2 Berufssprachkurs
//
//  Computes word row layout and text wrapping for PDFs.
//  Created: 05.04.26.
//

import Foundation
import UIKit

// MARK: - Word Layout

extension PDFGenerationService {
    /// Single layout pass for one word row: shared by pagination and live drawing.
    struct WordBlockLayoutResult {
        let germanText: String
        let germanHeight: CGFloat
        let translationHeight: CGFloat
        /// Explanation, synonyms, example — order matches draw order.
        let labeledRows: [(prefix: String, body: String, height: CGFloat)]
        let blockHeight: CGFloat
    }

    static func wordBlockLayout(
        word: WordData,
        wordIndex: Int,
        leftColumnWidth: CGFloat,
        rightColumnWidth: CGFloat,
        contentWidth: CGFloat
    ) -> WordBlockLayoutResult {
        let germanText = "\(wordIndex + 1). \(word.german)"
        let germanHeight = calculateTextHeight(text: germanText, width: leftColumnWidth, attributes: PDFGenerationMetrics.wordAttributes)

        let translationHeight: CGFloat
        if word.translation.isEmpty {
            translationHeight = 0
        } else {
            translationHeight = calculateTextHeight(text: word.translation, width: rightColumnWidth, attributes: PDFGenerationMetrics.wordAttributes)
        }

        var labeledRows: [(prefix: String, body: String, height: CGFloat)] = []

        if let explanation = word.explanation, !explanation.isEmpty {
            let prefix = Localizable.string(Localizable.wordRowDetailLabelExplanation)
            let attr = attributedLabeledLine(prefix: prefix, body: explanation)
            let h = attributedParagraphHeight(attr, width: contentWidth)
            labeledRows.append((prefix, explanation, h))
        }
        if let synonyms = word.synonyms, !synonyms.isEmpty {
            let synonymsText = synonyms.joined(separator: ", ")
            let prefix = Localizable.string(Localizable.wordRowDetailLabelSynonyms)
            let attr = attributedLabeledLine(prefix: prefix, body: synonymsText)
            let h = attributedParagraphHeight(attr, width: contentWidth)
            labeledRows.append((prefix, synonymsText, h))
        }
        if let example = word.example, !example.isEmpty {
            let prefix = Localizable.string(Localizable.wordRowDetailLabelExample)
            let attr = attributedLabeledLine(prefix: prefix, body: example)
            let h = attributedParagraphHeight(attr, width: contentWidth)
            labeledRows.append((prefix, example, h))
        }

        var leftY = germanHeight + PDFGenerationMetrics.germanAndLabeledRowGap
        for row in labeledRows {
            leftY += row.height + PDFGenerationMetrics.germanAndLabeledRowGap
        }
        let blockHeight = max(leftY, translationHeight)

        return WordBlockLayoutResult(
            germanText: germanText,
            germanHeight: germanHeight,
            translationHeight: translationHeight,
            labeledRows: labeledRows,
            blockHeight: blockHeight
        )
    }

    /// Bottom Y for body text (footer sits below this; smaller reserved band than before so more room for content).
    static func contentBottomY(pageHeight: CGFloat) -> CGFloat {
        pageHeight - PDFGenerationMetrics.footerBottomInset - PDFGenerationMetrics.footerReservedAbove
    }

    /// Splits word indices into pages; must match the live layout’s page breaks.
    static func paginateWords(
        words: [WordData],
        pageHeight: CGFloat,
        leftColumnWidth: CGFloat,
        rightColumnWidth: CGFloat,
        contentWidth: CGFloat
    ) -> [[Int]] {
        guard !words.isEmpty else { return [[]] }

        let bottomY = contentBottomY(pageHeight: pageHeight)
        var pages: [[Int]] = []
        var current: [Int] = []
        var cursorY: CGFloat = PDFGenerationMetrics.firstPageBodyStartY

        for index in words.indices {
            let layout = wordBlockLayout(
                word: words[index],
                wordIndex: index,
                leftColumnWidth: leftColumnWidth,
                rightColumnWidth: rightColumnWidth,
                contentWidth: contentWidth
            )
            let blockH = layout.blockHeight + PDFGenerationMetrics.blockSpacingAfterWord

            if cursorY + blockH > bottomY && !current.isEmpty {
                pages.append(current)
                current = []
                cursorY = PDFGenerationMetrics.continuationPageBodyStartY
            }
            current.append(index)
            cursorY += blockH
        }
        if !current.isEmpty {
            pages.append(current)
        }
        return pages
    }

    // MARK: - Text measurement (shared by layout + drawing)

    static func calculateTextHeight(text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedParagraphHeight(attributedString, width: width)
    }

    static func attributedParagraphHeight(_ attributedString: NSAttributedString, width: CGFloat) -> CGFloat {
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(boundingRect.height)
    }

    /// Localized abbreviation + period + space + body; prefix uses badge styling, body uses secondary styling.
    static func attributedLabeledLine(prefix: String, body: String) -> NSAttributedString {
        let m = NSMutableAttributedString(string: prefix, attributes: PDFGenerationMetrics.badgeAttributes)
        m.append(NSAttributedString(string: body, attributes: PDFGenerationMetrics.secondaryBodyAttributes))
        return m
    }
}
