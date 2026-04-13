//
//  FAQView.swift
//  B2 Berufssprachkurs
//
//  FAQ screen presenting frequently asked support information.
//  Created: 24.11.25.
//

import SwiftUI

// MARK: - Screen

struct FAQView: View {
    // MARK: View Layout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Localizable.string(Localizable.faq))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(Localizable.string(Localizable.faqDescription))
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
            .padding(.bottom, 32)
        }
        .navigationTitle(Localizable.string(Localizable.faq))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FAQView()
    }
}

