//
//  MyWordsPDFExport.swift
//  B2 Berufssprachkurs
//
//  Builds PDF exports for the user's My Words list.
//  Created: 04.04.26.
//

import SwiftUI

// MARK: - MyWordsPDFExport

enum MyWordsPDFExport {
    static func generatePDF(displayedEntries: [CustomWordEntry]) throws -> URL {
        let words = displayedEntries.map { $0.asWord() }
        let wordData = WordListShareManager.wordDataForPDF(
            words: words,
            translationProvider: { word in
                word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )
        let myWordsTitle = Localizable.string(Localizable.myWords).replacingOccurrences(of: "\n", with: " ")
        let pdfInfo = PDFGenerationService.PDFInfo(
            lectionTitle: myWordsTitle,
            lectionNumber: nil,
            sectionTitle: "",
            sectionLetter: nil,
            headerColor: Color("AppRed"),
            words: wordData,
            fileName: "MyWords",
            showsLectionSectionIndexing: false
        )
        return try PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }
}
