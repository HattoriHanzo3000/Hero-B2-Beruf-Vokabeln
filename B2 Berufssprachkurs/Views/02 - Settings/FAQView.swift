//
//  FAQView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct FAQView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // FAQ content block with rounded corners
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

#Preview {
    NavigationStack {
        FAQView()
    }
}

