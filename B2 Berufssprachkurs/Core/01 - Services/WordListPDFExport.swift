//
//  WordListPDFExport.swift
//  B2 Berufssprachkurs
//

import Foundation
import SwiftUI

enum WordListPDFExport {
    static func printJobName(
        sectionId: String,
        headerInfo: (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)?,
        stack: SectionStackPresentation.Info,
        prepositionSuffix: String,
        isVerbenOrAdjektive: Bool
    ) -> String {
        if let info = headerInfo {
            let lection = info.lectionTitle.replacingOccurrences(of: "\n", with: " ")
            let section = info.sectionTitle.replacingOccurrences(of: "\n", with: " ")
            return "\(lection) – \(section)"
        }
        if isVerbenOrAdjektive {
            return "\(stack.title) – \(prepositionSuffix)"
        }
        return stack.title.replacingOccurrences(of: "\n", with: " ")
    }

    static func generateWordsListPDF(
        sectionId: String,
        words: [Word],
        headerInfo: (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)?,
        stack: SectionStackPresentation.Info,
        prepositionSuffix: String,
        isVerbenSection: Bool,
        isAdjektiveSection: Bool,
        translationProvider: (Word) -> String
    ) -> URL {
        let lectionTitle: String
        let lectionNumber: String?
        let sectionTitle: String
        let sectionLetter: String?

        if let info = headerInfo {
            lectionTitle = info.lectionTitle
            lectionNumber = info.lectionNumber.isEmpty ? nil : info.lectionNumber
            sectionTitle = info.sectionTitle
            sectionLetter = info.sectionLetter.isEmpty ? nil : info.sectionLetter
        } else if isVerbenSection || isAdjektiveSection {
            lectionTitle = stack.title
            lectionNumber = nil
            sectionTitle = prepositionSuffix
            sectionLetter = nil
        } else {
            lectionTitle = stack.title
            lectionNumber = nil
            sectionTitle = ""
            sectionLetter = nil
        }

        let wordData = WordListShareManager.wordDataForPDF(
            words: words,
            translationProvider: { translationProvider($0) }
        )

        let showsLectionSectionIndexing = headerInfo != nil && !isVerbenSection && !isAdjektiveSection
        let pdfInfo = PDFGenerationService.PDFInfo(
            lectionTitle: lectionTitle,
            lectionNumber: lectionNumber,
            sectionTitle: sectionTitle,
            sectionLetter: sectionLetter,
            headerColor: stack.color,
            words: wordData,
            fileName: "WordsList_\(sectionId)",
            showsLectionSectionIndexing: showsLectionSectionIndexing
        )

        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }
}
