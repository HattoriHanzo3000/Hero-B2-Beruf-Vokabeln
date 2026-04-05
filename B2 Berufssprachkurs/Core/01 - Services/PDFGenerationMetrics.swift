//
//  PDFGenerationMetrics.swift
//  B2 Berufssprachkurs
//
//  Shared layout constants and text styles for word-list PDF export.
//

import UIKit

enum PDFGenerationMetrics {
    static let pageWidthPoints: CGFloat = 8.5 * 72.0
    static let pageHeightPoints: CGFloat = 11 * 72.0

    static let margin: CGFloat = 50
    /// Distance from the physical bottom of the page to the baseline of the footer line (Pages-like, low on the sheet).
    static let footerBottomInset: CGFloat = 18
    /// Space reserved above the footer so body text does not collide (line + gap).
    static let footerReservedAbove: CGFloat = 26
    /// Gap after the German line and between labeled detail rows (must match draw path).
    static let germanAndLabeledRowGap: CGFloat = 4
    /// Vertical space after each word block before the next entry.
    static let blockSpacingAfterWord: CGFloat = 12
    /// First line Y for lection title inside the colored header band.
    static let headerFirstLineY: CGFloat = 35
    /// Height of the colored header band on page 1.
    static let headerBandHeight: CGFloat = 100
    /// Vertical gap between lection title and section subtitle in the header.
    static let headerLectionToSectionSpacing: CGFloat = 6
    /// Body text starts below the header on page 1 (matches pagination cursor).
    static let firstPageBodyStartY: CGFloat = 120
    /// Body text start Y on continuation pages (matches pagination after page break).
    static let continuationPageBodyStartY: CGFloat = 60
    /// Horizontal gap reserved between left footer text and page label.
    static let footerLeftRightColumnGap: CGFloat = 24
    /// Space between left and right word columns.
    static let columnSpacing: CGFloat = 20

    static let wordAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: UIColor.black
    ]

    static let badgeAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
        .foregroundColor: UIColor.black.withAlphaComponent(0.55)
    ]

    static let secondaryBodyAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: UIColor.black.withAlphaComponent(0.55)
    ]

    static let footerAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 8, weight: .regular),
        .foregroundColor: UIColor.black.withAlphaComponent(0.45)
    ]
}
