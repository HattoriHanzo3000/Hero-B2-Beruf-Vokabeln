//
//  AboutView.swift
//  B2 Berufssprachkurs
//
//  About screen describing app purpose and disclaimer information.
//  Created: 24.11.25.
//

import SwiftUI

// MARK: - Layout

private enum AboutLayout {
    static let textBlockSpacing: CGFloat = 24
}

// MARK: - Screen

struct AboutView: View {
    // MARK: Derived Data

    private var appName: String {
        if let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !displayName.isEmpty {
            return displayName
        }
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !bundleName.isEmpty {
            return bundleName
        }
        return "Hero"
    }

    private var aboutDescriptionText: Text {
        let testName = Text(Localizable.string(Localizable.aboutOfficialTestName))
            .fontWeight(.medium)
            .italic()
            .foregroundColor(Color("AppGreenThird"))
        
        let bookTitle = Text(Localizable.string(Localizable.aboutOfficialBookTitle))
            .fontWeight(.medium)
            .italic()
            .foregroundColor(Color("AppGreenThird"))
            
        return Text("\(Text(appName))\(Text(Localizable.string(Localizable.aboutAppDescLead)))\(testName)\(Text(Localizable.string(Localizable.aboutAppDescMid)))\(bookTitle)\(Text(Localizable.string(Localizable.aboutAppDescTail)))")
    }

    private var disclaimerText: String {
        String(
            format: Localizable.string(Localizable.aboutDisclaimer),
            appName
        )
    }

    // MARK: View Layout

    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image("MascotLaunch")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: AboutLayout.textBlockSpacing) {
                        aboutDescriptionText
                            .font(.body)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(disclaimerText)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
        .navigationTitle(Localizable.string(Localizable.about))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
            .environmentObject(DataService())
    }
}
