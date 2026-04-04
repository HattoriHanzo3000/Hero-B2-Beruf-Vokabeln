//
//  QRCodeView.swift
//  B2 Berufssprachkurs
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct QRCodeView: View {
    let url: String

    var body: some View {
        if let qrCodeImage = QRCodeImageGenerator.image(for: url) {
            Image(uiImage: qrCodeImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
        }
    }
}

enum QRCodeImageGenerator {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    static func image(for string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
