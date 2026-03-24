//
//  ShareView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showShareSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    // App Store URL - universal format that works across all regions
    private let appStoreURL = "https://apps.apple.com/app/id6755700752"
    
    // App Store URL for opening - uses universal format
    private var appStoreOpenURL: String {
        // Universal format without country code - App Store will redirect to user's region
        return appStoreURL
    }
    
    // Share text
    private var shareText: String {
        let appName = "Hero - Deutsch B2 Beruf"
        return "\(appName)\n\(appStoreURL)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // QR Code Section
                VStack(spacing: 16) {
                    Text(Localizable.string(Localizable.scanQRCode))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.primary)
                    
                    // QR Code
                    QRCodeView(url: appStoreURL)
                        .frame(width: 280, height: 280)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Text(Localizable.string(Localizable.scanToDownload))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Open in App Store Button
                Button {
                    HapticManager.shared.lightImpact()
                    if let url = URL(string: appStoreOpenURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(Localizable.string(Localizable.openInAppStore))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AppGreen"), Color("AppBlue")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            .padding(.bottom, 24)
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
                        .font(.body)
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
