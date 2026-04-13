//
//  PDFGenerationService.swift
//  B2 Berufssprachkurs
//
//  Public service entry point for building words-list PDFs.
//  Created: 30.11.25.
//

import SwiftUI
import UIKit

// MARK: - PDFGenerationError

enum PDFGenerationError: Error {
    case couldNotWritePDF(underlying: Error)
}

// MARK: - Service

struct PDFGenerationService {
    // MARK: Models

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

    // MARK: Public API

    static func generateWordsListPDF(info: PDFInfo) throws -> URL {
        let pdfTitle = "\(info.lectionTitle)\(info.sectionTitle.isEmpty ? "" : " - \(info.sectionTitle)")"
        let pageWidth = PDFGenerationMetrics.pageWidthPoints
        let pageHeight = PDFGenerationMetrics.pageHeightPoints
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let data = pdfDataForWordsList(
            info: info,
            documentTitle: pdfTitle,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
            pageRect: pageRect
        )

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(info.fileName).pdf")
        do {
            try data.write(to: tempURL, options: .atomic)
        } catch {
            throw PDFGenerationError.couldNotWritePDF(underlying: error)
        }
        return tempURL
    }
}
