//
//  MyWordsPDFExport.swift
//  B2 Berufssprachkurs
//
//  PDF generation for the “My Words” list (print / share).
//

import SwiftUI

enum MyWordsPDFExport {
    static func generatePDF(displayedEntries: [CustomWordEntry]) -> URL {
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
        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }
}
