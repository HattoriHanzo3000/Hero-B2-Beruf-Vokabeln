//
//  PDFGenerationDocumentRenderer.swift
//  B2 Berufssprachkurs
//
//  UIGraphicsPDFRenderer pass for word-list export.
//

import SwiftUI
import UIKit

extension PDFGenerationService {
    static func pdfDataForWordsList(
        info: PDFInfo,
        documentTitle: String,
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        pageRect: CGRect
    ) -> Data {
        let margin = PDFGenerationMetrics.margin
        let contentWidth = pageWidth - (margin * 2)
        let columnSpacing = PDFGenerationMetrics.columnSpacing
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

        let pdfMetaData = [
            kCGPDFContextCreator: "B2 Berufssprachkurs",
            kCGPDFContextAuthor: "Hero - Deutsch B2 Beruf",
            kCGPDFContextTitle: documentTitle
        ] as [String: Any]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            for (pageIndex, indicesOnPage) in pageIndices.enumerated() {
                context.beginPage()

                let isFirstPage = pageIndex == 0

                if isFirstPage {
                    let headerColor = UIColor(info.headerColor)
                    let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: PDFGenerationMetrics.headerBandHeight)
                    headerColor.setFill()
                    context.cgContext.fill(headerRect)

                    var headerY: CGFloat = PDFGenerationMetrics.headerFirstLineY
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
                    headerY += lectionSize.height + PDFGenerationMetrics.headerLectionToSectionSpacing

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

                var yPosition: CGFloat = isFirstPage
                    ? PDFGenerationMetrics.firstPageBodyStartY
                    : PDFGenerationMetrics.continuationPageBodyStartY

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
                    layout.germanText.draw(in: germanRect, withAttributes: PDFGenerationMetrics.wordAttributes)
                    leftY += layout.germanHeight + PDFGenerationMetrics.germanAndLabeledRowGap

                    if !word.translation.isEmpty {
                        let translationRect = CGRect(
                            x: rightColumnX,
                            y: startY,
                            width: rightColumnWidth,
                            height: layout.translationHeight
                        )
                        word.translation.draw(in: translationRect, withAttributes: PDFGenerationMetrics.wordAttributes)
                    }

                    for row in layout.labeledRows {
                        drawLabeledRow(prefix: row.prefix, body: row.body, at: leftY)
                        leftY += row.height + PDFGenerationMetrics.germanAndLabeledRowGap
                    }

                    yPosition += layout.blockHeight + PDFGenerationMetrics.blockSpacingAfterWord
                }

                drawRunningFooter(
                    pageWidth: pageWidth,
                    pageHeight: pageHeight,
                    documentTitle: documentTitle,
                    pageNumber: pageIndex + 1,
                    totalPages: totalPages,
                    lectionNumber: info.lectionNumber,
                    sectionLetter: info.sectionLetter,
                    showsLectionSectionIndexing: info.showsLectionSectionIndexing
                )
            }
        }
    }
}
