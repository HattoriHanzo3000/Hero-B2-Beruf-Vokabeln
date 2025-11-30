//
//  PDFGenerationService.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import PDFKit

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
    }
    
    static func generateWordsListPDF(info: PDFInfo) -> URL {
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
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 60
            let margin: CGFloat = 50
            let contentWidth = pageWidth - (margin * 2)
            
            // Header with app-style design
            let headerColor = UIColor(info.headerColor)
            let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 100)
            headerColor.setFill()
            context.cgContext.fill(headerRect)
            
            var headerY: CGFloat = 35
            
            // First row: Lection title with number
            let lectionText: String
            if let number = info.lectionNumber, !number.isEmpty {
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
            
            // Second row: Section title with letter
            if !info.sectionTitle.isEmpty {
                let sectionText: String
                if let letter = info.sectionLetter, !letter.isEmpty {
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
            
            yPosition = 120
            
            // Two-column layout
            let columnSpacing: CGFloat = 20
            let leftColumnWidth = (contentWidth - columnSpacing) * 0.55
            let rightColumnWidth = (contentWidth - columnSpacing) * 0.45
            let leftColumnX = margin
            let rightColumnX = margin + leftColumnWidth + columnSpacing
            
            // Words list with two-column layout (all sizes reduced by 3)
            let wordAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            
            let exampleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.black.withAlphaComponent(0.6)
            ]
            
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: UIColor.black.withAlphaComponent(0.6)
            ]
            
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            
            for (index, word) in info.words.enumerated() {
                // Check if we need a new page
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 60
                }
                
                let startY = yPosition
                var leftY = startY
                var rightY = startY
                
                // Helper function to calculate text height with wrapping
                func calculateTextHeight(text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
                    let attributedString = NSAttributedString(string: text, attributes: attributes)
                    let boundingRect = attributedString.boundingRect(
                        with: CGSize(width: width, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        context: nil
                    )
                    return ceil(boundingRect.height)
                }
                
                // LEFT COLUMN: German word with example
                // German word
                let germanText = "\(index + 1). \(word.german)"
                let germanHeight = calculateTextHeight(text: germanText, width: leftColumnWidth, attributes: wordAttributes)
                let germanRect = CGRect(x: leftColumnX, y: leftY, width: leftColumnWidth, height: germanHeight)
                germanText.draw(in: germanRect, withAttributes: wordAttributes)
                leftY += germanHeight + 4
                
                // Example sentence
                if let example = word.example, !example.isEmpty {
                    let exampleHeight = calculateTextHeight(text: example, width: leftColumnWidth, attributes: exampleAttributes)
                    let exampleRect = CGRect(x: leftColumnX, y: leftY, width: leftColumnWidth, height: exampleHeight)
                    example.draw(in: exampleRect, withAttributes: exampleAttributes)
                    leftY += exampleHeight + 4
                }
                
                // RIGHT COLUMN: Explanation, Synonyms, Translation
                // All content aligned in the same column after labels
                let labelColumnWidth: CGFloat = 45
                let contentStartX = rightColumnX + labelColumnWidth
                let contentWidth = rightColumnWidth - labelColumnWidth
                
                // First row: Explanation
                if let explanation = word.explanation, !explanation.isEmpty {
                    let explanationLabel = "erkl.:"
                    let explanationLabelHeight = calculateTextHeight(text: explanationLabel, width: labelColumnWidth, attributes: labelAttributes)
                    let explanationLabelRect = CGRect(x: rightColumnX, y: rightY, width: labelColumnWidth, height: explanationLabelHeight)
                    explanationLabel.draw(in: explanationLabelRect, withAttributes: labelAttributes)
                    
                    let explanationHeight = calculateTextHeight(text: explanation, width: contentWidth, attributes: contentAttributes)
                    let explanationRect = CGRect(x: contentStartX, y: rightY, width: contentWidth, height: explanationHeight)
                    explanation.draw(in: explanationRect, withAttributes: contentAttributes)
                    rightY += max(explanationLabelHeight, explanationHeight) + 4
                }
                
                // Second row: Synonyms
                if let synonyms = word.synonyms, !synonyms.isEmpty {
                    let synonymsText = synonyms.joined(separator: ", ")
                    let synonymsLabel = "syn.:"
                    let synonymsLabelHeight = calculateTextHeight(text: synonymsLabel, width: labelColumnWidth, attributes: labelAttributes)
                    let synonymsLabelRect = CGRect(x: rightColumnX, y: rightY, width: labelColumnWidth, height: synonymsLabelHeight)
                    synonymsLabel.draw(in: synonymsLabelRect, withAttributes: labelAttributes)
                    
                    let synonymsHeight = calculateTextHeight(text: synonymsText, width: contentWidth, attributes: contentAttributes)
                    let synonymsRect = CGRect(x: contentStartX, y: rightY, width: contentWidth, height: synonymsHeight)
                    synonymsText.draw(in: synonymsRect, withAttributes: contentAttributes)
                    rightY += max(synonymsLabelHeight, synonymsHeight) + 4
                }
                
                // Third row: Translation
                if !word.translation.isEmpty {
                    let translationLabel = "übers.:"
                    let translationLabelHeight = calculateTextHeight(text: translationLabel, width: labelColumnWidth, attributes: labelAttributes)
                    let translationLabelRect = CGRect(x: rightColumnX, y: rightY, width: labelColumnWidth, height: translationLabelHeight)
                    translationLabel.draw(in: translationLabelRect, withAttributes: labelAttributes)
                    
                    let translationHeight = calculateTextHeight(text: word.translation, width: contentWidth, attributes: contentAttributes)
                    let translationRect = CGRect(x: contentStartX, y: rightY, width: contentWidth, height: translationHeight)
                    word.translation.draw(in: translationRect, withAttributes: contentAttributes)
                    rightY += max(translationLabelHeight, translationHeight) + 4
                }
                
                // Move to next row based on the tallest column
                let maxHeight = max(leftY - startY, rightY - startY)
                yPosition += maxHeight + 12 // Space between words
            }
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(info.fileName).pdf")
        try? data.write(to: tempURL)
        return tempURL
    }
}

