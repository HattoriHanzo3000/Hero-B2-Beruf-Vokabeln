//
//  PDFGenerationService.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

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
    
    /// Height of one word block (must match drawing logic).
    private static func wordBlockHeight(
        word: WordData,
        index: Int,
        leftColumnWidth: CGFloat,
        rightColumnWidth: CGFloat,
        contentWidth: CGFloat
    ) -> CGFloat {
        func labeledRowHeight(prefix: String, body: String) -> CGFloat {
            let attr = attributedLabeledLine(prefix: prefix, body: body)
            return attributedParagraphHeight(attr, width: contentWidth)
        }
        
        var leftY: CGFloat = 0
        let germanText = "\(index + 1). \(word.german)"
        let germanHeight = calculateTextHeight(text: germanText, width: leftColumnWidth, attributes: wordAttributes)
        leftY += germanHeight + 4
        
        var rightH: CGFloat = 0
        if !word.translation.isEmpty {
            rightH = calculateTextHeight(text: word.translation, width: rightColumnWidth, attributes: wordAttributes)
        }
        
        if let explanation = word.explanation, !explanation.isEmpty {
            leftY += labeledRowHeight(prefix: Localizable.string(Localizable.wordRowDetailLabelExplanation), body: explanation) + 4
        }
        if let synonyms = word.synonyms, !synonyms.isEmpty {
            let synonymsText = synonyms.joined(separator: ", ")
            leftY += labeledRowHeight(prefix: Localizable.string(Localizable.wordRowDetailLabelSynonyms), body: synonymsText) + 4
        }
        if let example = word.example, !example.isEmpty {
            leftY += labeledRowHeight(prefix: Localizable.string(Localizable.wordRowDetailLabelExample), body: example) + 4
        }
        
        let leftSpan = leftY
        return max(leftSpan, rightH)
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
        var cursorY: CGFloat = 120
        
        for index in words.indices {
            let blockH = wordBlockHeight(
                word: words[index],
                index: index,
                leftColumnWidth: leftColumnWidth,
                rightColumnWidth: rightColumnWidth,
                contentWidth: contentWidth
            ) + 12
            
            if cursorY + blockH > bottomY && !current.isEmpty {
                pages.append(current)
                current = []
                cursorY = 60
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
        let columnSpacing: CGFloat = 20
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
                    let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 100)
                    headerColor.setFill()
                    context.cgContext.fill(headerRect)
                    
                    var headerY: CGFloat = 35
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
                    headerY += lectionSize.height + 6
                    
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
                
                var yPosition: CGFloat = isFirstPage ? 120 : 60
                
                func drawLabeledRow(prefix: String, body: String, at y: CGFloat) -> CGFloat {
                    let attr = attributedLabeledLine(prefix: prefix, body: body)
                    let h = attributedParagraphHeight(attr, width: contentWidth)
                    let rect = CGRect(x: margin, y: y, width: contentWidth, height: h)
                    attr.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                    return h
                }
                
                for wordIndex in indicesOnPage {
                    let word = info.words[wordIndex]
                    let startY = yPosition
                    var leftY = startY
                    
                    let germanText = "\(wordIndex + 1). \(word.german)"
                    let germanHeight = calculateTextHeight(text: germanText, width: leftColumnWidth, attributes: wordAttributes)
                    let germanRect = CGRect(x: leftColumnX, y: leftY, width: leftColumnWidth, height: germanHeight)
                    germanText.draw(in: germanRect, withAttributes: wordAttributes)
                    leftY += germanHeight + 4
                    
                    var rightColumnHeight: CGFloat = 0
                    if !word.translation.isEmpty {
                        let translationHeight = calculateTextHeight(text: word.translation, width: rightColumnWidth, attributes: wordAttributes)
                        let translationRect = CGRect(x: rightColumnX, y: startY, width: rightColumnWidth, height: translationHeight)
                        word.translation.draw(in: translationRect, withAttributes: wordAttributes)
                        rightColumnHeight = translationHeight
                    }
                    
                    if let explanation = word.explanation, !explanation.isEmpty {
                        let h = drawLabeledRow(prefix: Localizable.string(Localizable.wordRowDetailLabelExplanation), body: explanation, at: leftY)
                        leftY += h + 4
                    }
                    if let synonyms = word.synonyms, !synonyms.isEmpty {
                        let synonymsText = synonyms.joined(separator: ", ")
                        let h = drawLabeledRow(prefix: Localizable.string(Localizable.wordRowDetailLabelSynonyms), body: synonymsText, at: leftY)
                        leftY += h + 4
                    }
                    if let example = word.example, !example.isEmpty {
                        let h = drawLabeledRow(prefix: Localizable.string(Localizable.wordRowDetailLabelExample), body: example, at: leftY)
                        leftY += h + 4
                    }
                    
                    let leftColumnSpan = leftY - startY
                    let blockHeight = max(leftColumnSpan, rightColumnHeight)
                    yPosition += blockHeight + 12
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
        let pageLabel = "Seite \(pageNumber) von \(totalPages)"
        
        let leftSize = leftFooterText.size(withAttributes: footerAttributes)
        let pageSize = pageLabel.size(withAttributes: footerAttributes)
        
        let leftRect = CGRect(
            x: margin,
            y: footerY - leftSize.height,
            width: max(0, pageWidth - margin * 2 - pageSize.width - 24),
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
