//
//  PDFGenerationFooterDrawing.swift
//  B2 Berufssprachkurs
//
//  Draws reusable footer content for generated PDF pages.
//  Created: 05.04.26.
//

import UIKit

// MARK: - Footer Drawing

extension PDFGenerationService {
    /// Running footer: general lists use `1A: …`; other lists use the document title only (no page-number prefix).
    static func drawRunningFooter(
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

        let footerY = pageHeight - PDFGenerationMetrics.footerBottomInset
        let pageLabel = String(
            format: Localizable.string(Localizable.pdfPageOfTotalFormat),
            pageNumber,
            totalPages
        )

        let leftSize = leftFooterText.size(withAttributes: PDFGenerationMetrics.footerAttributes)
        let pageSize = pageLabel.size(withAttributes: PDFGenerationMetrics.footerAttributes)

        let leftRect = CGRect(
            x: PDFGenerationMetrics.margin,
            y: footerY - leftSize.height,
            width: max(0, pageWidth - PDFGenerationMetrics.margin * 2 - pageSize.width - PDFGenerationMetrics.footerLeftRightColumnGap),
            height: leftSize.height
        )
        leftFooterText.draw(in: leftRect, withAttributes: PDFGenerationMetrics.footerAttributes)

        let pageRect = CGRect(
            x: pageWidth - PDFGenerationMetrics.margin - pageSize.width,
            y: footerY - pageSize.height,
            width: pageSize.width,
            height: pageSize.height
        )
        pageLabel.draw(in: pageRect, withAttributes: PDFGenerationMetrics.footerAttributes)
    }
}
