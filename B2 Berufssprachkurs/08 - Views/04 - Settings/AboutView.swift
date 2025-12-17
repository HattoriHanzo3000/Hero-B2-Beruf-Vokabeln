//
//  AboutView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AboutView: View {
    // Get current app version (without build number)
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Mascot launch image
                Image("MascotLaunch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                
                // App description block with rounded corners
                VStack(alignment: .leading, spacing: 12) {
                    Text(Localizable.string(Localizable.aboutThisApp))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(Localizable.string(Localizable.aboutAppDescription))
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                
                Spacer()
                
                // Version info at bottom
                Text("\(Localizable.string(Localizable.version)) \(appVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(16)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 60) // Space for fixed banner ad
        }
        .safeAreaInset(edge: .bottom) {
            BannerAd()
                .background(Color(.systemGroupedBackground))
        }
        .navigationTitle(Localizable.string(Localizable.about))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

