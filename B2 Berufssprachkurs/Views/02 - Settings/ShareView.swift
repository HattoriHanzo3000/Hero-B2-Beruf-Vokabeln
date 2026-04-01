//
//  ShareView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareView: View {
    @State private var showShareSheet = false

    private var appStoreURL: String { AppStoreService.defaultListingURL }

    // Share text
    private var shareText: String {
        let appName = "Hero - Deutsch B2 Beruf"
        return "\(appName)\n\(appStoreURL)"
    }
    
    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView {
                VStack(spacing: 24) {
                    QRCodeView(url: appStoreURL)
                        .frame(width: 280, height: 280)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.top, 20)

                    Text(Localizable.string(Localizable.shareScreenFooter))
                        .font(.system(.body, design: .default, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer(minLength: 24)
                }
                .padding(.vertical, 20)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
        .navigationTitle(Localizable.string(Localizable.share))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.lightImpact()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .navigationBarSymbolStyle()
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Share")
                .accessibilityHint("Share the app")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let appStoreLink = URL(string: appStoreURL) {
                ShareSheet(activityItems: [shareText, appStoreLink])
            } else {
                ShareSheet(activityItems: [shareText])
            }
        }
    }
}

// MARK: - QR Code View
struct QRCodeView: View {
    let url: String
    
    var body: some View {
        if let qrCodeImage = generateQRCode(from: url) {
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
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        // Set the input message for QR code
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        
        // Set correction level for better error tolerance
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Scale up the image for better quality
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        // Create CGImage from CIImage
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    NavigationStack {
        ShareView()
    }
}
