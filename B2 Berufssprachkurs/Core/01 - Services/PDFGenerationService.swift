//
//  PDFGenerationService.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit

enum PDFGenerationError: Error {
    case couldNotWritePDF(underlying: Error)
}

struct PDFGenerationService {
    struct WordData {
        let german: String
        let example: String?
        let explanation: String?
        let translation: String
        let synonyms: [String]?
    }

    struct PDFInfo {
        let lectionTitle: String
        let lectionNumber: String?
        let sectionTitle: String
        let sectionLetter: String?
        let headerColor: Color
        let words: [WordData]
        let fileName: String
        /// General curriculum lists: lection index + section letter (e.g. footer `1A:`). Verbs, adjectives, My Words, and Favorites use titles only.
        let showsLectionSectionIndexing: Bool
    }

    private static let margin: CGFloat = 50
    /// Distance from the physical bottom of the page to the baseline of the footer line (Pages-like, low on the sheet).
    private static let footerBottomInset: CGFloat = 18
    /// Space reserved above the footer so body text does not collide (line + gap).
    private static let footerReservedAbove: CGFloat = 26
    /// Gap after the German line and between labeled detail rows (must match draw path).
    private static let germanAndLabeledRowGap: CGFloat = 4
    /// Vertical space after each word block before the next entry.
    private static let blockSpacingAfterWord: CGFloat = 12
    /// First line Y for lection title inside the colored header band.
    private static let headerFirstLineY: CGFloat = 35
    /// Height of the colored header band on page 1.
    private static let headerBandHeight: CGFloat = 100
    /// Vertical gap between lection title and section subtitle in the header.
    private static let headerLectionToSectionSpacing: CGFloat = 6
    /// Body text starts below the header on page 1 (matches pagination cursor).
    private static let firstPageBodyStartY: CGFloat = 120
    /// Body text start Y on continuation pages (matches pagination after page break).
    private static let continuationPageBodyStartY: CGFloat = 60
    /// Horizontal gap reserved between left footer text and page label.
    private static let footerLeftRightColumnGap: CGFloat = 24
    /// Space between left and right word columns.
    private static let columnSpacing: CGFloat = 20

    private static let wordAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: UIColor.black
    ]

    private static let badgeAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
        .foregroundColor: UIColor.black.withAlphaComponent(0.55)
    ]

    private static let secondaryBodyAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: UIColor.black.withAlphaComponent(0.55)
    ]

    private static let footerAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: UIColor.black.withAlphaComponent(0.45)
    ]

    private static func calculateTextHeight(text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedParagraphHeight(attributedString, width: width)
    }

    private static func attributedParagraphHeight(_ attributedString: NSAttributedString, width: CGFloat) -> CGFloat {
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(boundingRect.height)
    }

    /// Localized abbreviation + period + space + body; prefix uses badge styling, body uses secondary styling.
    private static func attributedLabeledLine(prefix: String, body: String) -> NSAttributedString {
        let m = NSMutableAttributedString(string: prefix, attributes: badgeAttributes)
        m.append(NSAttributedString(string: body, attributes: secondaryBodyAttributes))
        return m
    }

    /// Single layout pass for one word row: shared by pagination and live drawing.
    private struct WordBlockLayoutResult {
        let germanText: String
        let germanHeight: CGFloat
        let translationHeight: CGFloat
        /// Explanation, synonyms, example — order matches draw order.
        let labeledRows: [(prefix: String, body: String, height: CGFloat)]
        let blockHeight: CGFloat
    }

    private static func wordBlockLayout(
        word: WordData,
        wordIndex: Int,
        leftColumnWidth: CGFloat,
        rightColumnWidth: CGFloat,
        contentWidth: CGFloat
    ) -> WordBlockLayoutResult {
        let germanText = "\(wordIndex + 1). \(word.german)"
        let germanHeight = calculateTextHeight(text: germanText, width: leftColumnWidth, attributes: wordAttributes)

        let translationHeight: CGFloat
        if word.translation.isEmpty {
            translationHeight = 0
        } else {
            translationHeight = calculateTextHeight(text: word.translation, width: rightColumnWidth, attributes: wordAttributes)
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

        var leftY = germanHeight + germanAndLabeledRowGap
        for row in labeledRows {
            leftY += row.height + germanAndLabeledRowGap
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
    private static func contentBottomY(pageHeight: CGFloat) -> CGFloat {
        pageHeight - footerBottomInset - footerReservedAbove
    }

    /// Splits word indices into pages; must match the live layout’s page breaks.
    private static func paginateWords(
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
        var cursorY: CGFloat = firstPageBodyStartY

        for index in words.indices {
            let layout = wordBlockLayout(
                word: words[index],
                wordIndex: index,
                leftColumnWidth: leftColumnWidth,
                rightColumnWidth: rightColumnWidth,
                contentWidth: contentWidth
            )
            let blockH = layout.blockHeight + blockSpacingAfterWord

            if cursorY + blockH > bottomY && !current.isEmpty {
                pages.append(current)
                current = []
                cursorY = continuationPageBodyStartY
            }
            current.append(index)
            cursorY += blockH
        }
        if !current.isEmpty {
            pages.append(current)
        }
        return pages
    }

    static func generateWordsListPDF(info: PDFInfo) throws -> URL {
        let pdfTitle = "\(info.lectionTitle)\(info.sectionTitle.isEmpty ? "" : " - \(info.sectionTitle)")"
        let pdfMetaData = [
            kCGPDFContextCreator: "B2 Berufssprachkurs",
            kCGPDFContextAuthor: "Hero - Deutsch B2 Beruf",
            kCGPDFContextTitle: pdfTitle
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let contentWidth = pageWidth - (margin * 2)
        let leftColumnWidth = (contentWidth - columnSpacing) * 0.55
        let rightColumnWidth = (contentWidth - columnSpacing) * 0.45
        let leftColumnX = margin
        let rightColumnX = margin + leftColumnWidth + columnSpacing

        let pageIndices = paginateWords(
            words: info.words,
            pageHeight: pageHeight,
            leftColumnWidth: leftColumnWidth,
            rightColumnWidth: rightColumnWidth,
            contentWidth: contentWidth
        )
        let totalPages = max(pageIndices.count, 1)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            for (pageIndex, indicesOnPage) in pageIndices.enumerated() {
                context.beginPage()

                let isFirstPage = pageIndex == 0

                if isFirstPage {
                    let headerColor = UIColor(info.headerColor)
                    let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: headerBandHeight)
                    headerColor.setFill()
                    context.cgContext.fill(headerRect)

                    var headerY: CGFloat = headerFirstLineY
                    let lectionText: String
                    if info.showsLectionSectionIndexing, let number = info.lectionNumber, !number.isEmpty {
                        lectionText = "\(number) \(info.lectionTitle)"
                    } else {
                        lectionText = info.lectionTitle
                    }

                    let lectionAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 23, weight: .bold),
                        .foregroundColor: UIColor.white
                    ]
                    let lectionSize = lectionText.size(withAttributes: lectionAttributes)
                    let lectionRect = CGRect(x: margin, y: headerY, width: contentWidth, height: lectionSize.height)
                    lectionText.draw(in: lectionRect, withAttributes: lectionAttributes)
                    headerY += lectionSize.height + headerLectionToSectionSpacing

                    if !info.sectionTitle.isEmpty {
                        let sectionText: String
                        if info.showsLectionSectionIndexing, let letter = info.sectionLetter, !letter.isEmpty {
                            sectionText = "\(letter.uppercased()) \(info.sectionTitle)"
                        } else {
                            sectionText = info.sectionTitle
                        }
                        let sectionAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
                        ]
                        let sectionSize = sectionText.size(withAttributes: sectionAttributes)
                        let sectionRect = CGRect(x: margin, y: headerY, width: contentWidth, height: sectionSize.height)
                        sectionText.draw(in: sectionRect, withAttributes: sectionAttributes)
                    }
                }

                var yPosition: CGFloat = isFirstPage ? firstPageBodyStartY : continuationPageBodyStartY

                func drawLabeledRow(prefix: String, body: String, at y: CGFloat) {
                    let attr = attributedLabeledLine(prefix: prefix, body: body)
                    let h = attributedParagraphHeight(attr, width: contentWidth)
                    let rect = CGRect(x: margin, y: y, width: contentWidth, height: h)
                    attr.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                }

                for wordIndex in indicesOnPage {
                    let word = info.words[wordIndex]
                    let layout = wordBlockLayout(
                        word: word,
                        wordIndex: wordIndex,
                        leftColumnWidth: leftColumnWidth,
                        rightColumnWidth: rightColumnWidth,
                        contentWidth: contentWidth
                    )

                    let startY = yPosition
                    var leftY = startY

                    let germanRect = CGRect(x: leftColumnX, y: leftY, width: leftColumnWidth, height: layout.germanHeight)
                    layout.germanText.draw(in: germanRect, withAttributes: wordAttributes)
                    leftY += layout.germanHeight + germanAndLabeledRowGap

                    if !word.translation.isEmpty {
                        let translationRect = CGRect(
                            x: rightColumnX,
                            y: startY,
                            width: rightColumnWidth,
                            height: layout.translationHeight
                        )
                        word.translation.draw(in: translationRect, withAttributes: wordAttributes)
                    }

                    for row in layout.labeledRows {
                        drawLabeledRow(prefix: row.prefix, body: row.body, at: leftY)
                        leftY += row.height + germanAndLabeledRowGap
                    }

                    yPosition += layout.blockHeight + blockSpacingAfterWord
                }

                drawRunningFooter(
                    pageWidth: pageWidth,
                    pageHeight: pageHeight,
                    documentTitle: pdfTitle,
                    pageNumber: pageIndex + 1,
                    totalPages: totalPages,
                    lectionNumber: info.lectionNumber,
                    sectionLetter: info.sectionLetter,
                    showsLectionSectionIndexing: info.showsLectionSectionIndexing
                )
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(info.fileName).pdf")
        do {
            try data.write(to: tempURL, options: .atomic)
        } catch {
            throw PDFGenerationError.couldNotWritePDF(underlying: error)
        }
        return tempURL
    }

    /// Running footer: general lists use `1A: …`; other lists use the document title only (no page-number prefix).
    private static func drawRunningFooter(
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        documentTitle: String,
        pageNumber: Int,
        totalPages: Int,
        lectionNumber: String?,
        sectionLetter: String?,
        showsLectionSectionIndexing: Bool
    ) {
        let leftFooterText: String
        if showsLectionSectionIndexing {
            let num = lectionNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let letter = sectionLetter?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
            let refPrefix: String
            if !num.isEmpty, !letter.isEmpty {
                refPrefix = "\(num)\(letter)"
            } else if !num.isEmpty {
                refPrefix = num
            } else if !letter.isEmpty {
                refPrefix = letter
            } else {
                refPrefix = "\(pageNumber)"
            }
            leftFooterText = "\(refPrefix): \(documentTitle)"
        } else {
            leftFooterText = documentTitle
        }

        let footerY = pageHeight - footerBottomInset
        let pageLabel = String(
            format: Localizable.string(Localizable.pdfPageOfTotalFormat),
            pageNumber,
            totalPages
        )

        let leftSize = leftFooterText.size(withAttributes: footerAttributes)
        let pageSize = pageLabel.size(withAttributes: footerAttributes)

        let leftRect = CGRect(
            x: margin,
            y: footerY - leftSize.height,
            width: max(0, pageWidth - margin * 2 - pageSize.width - footerLeftRightColumnGap),
            height: leftSize.height
        )
        leftFooterText.draw(in: leftRect, withAttributes: footerAttributes)

        let pageRect = CGRect(
            x: pageWidth - margin - pageSize.width,
            y: footerY - pageSize.height,
            width: pageSize.width,
            height: pageSize.height
        )
        pageLabel.draw(in: pageRect, withAttributes: footerAttributes)
    }
}
