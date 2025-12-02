//
//  AboutView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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

