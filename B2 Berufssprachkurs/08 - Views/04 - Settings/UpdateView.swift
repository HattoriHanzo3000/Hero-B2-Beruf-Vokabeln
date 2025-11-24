//
//  UpdateView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit

struct UpdateView: View {
    @State private var latestVersion: String = "1.0" // TODO: Fetch from server or App Store
    @State private var hasUpdate: Bool = false
    
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            SwiftUI.Section(Localizable.string(Localizable.currentVersion)) {
                versionCard(
                    title: "\(Localizable.string(Localizable.version)) \(currentVersion) (\(buildNumber))",
                    description: Localizable.string(Localizable.versionUpdates)
                )
            }
            
            if hasUpdate {
                SwiftUI.Section(Localizable.string(Localizable.updateAvailable)) {
                    versionCard(
                        title: "\(Localizable.string(Localizable.version)) \(latestVersion)",
                        description: Localizable.string(Localizable.versionUpdatesPlaceholder)
                    )
                    
                    Button {
                        openAppStore()
                    } label: {
                        Text(Localizable.string(Localizable.updateNow))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, 8)
                    .accessibilityHint(Localizable.string(Localizable.updateButtonHint))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localizable.string(Localizable.update))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkForUpdate()
        }
    }
    
    private func versionCard(title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            appIcon
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }
    
    private var appIcon: Image {
        if let iconName = UIApplication.shared.alternateIconName,
           let image = UIImage(named: iconName) {
            return Image(uiImage: image)
        }
        
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last,
           let image = UIImage(named: lastIcon) {
            return Image(uiImage: image)
        }
        
        return Image(systemName: "app.fill")
    }
    
    private func checkForUpdate() {
        // TODO: Implement version checking logic
        // For now, set hasUpdate to false
        hasUpdate = false
    }
    
    private func openAppStore() {
        // TODO: Replace with actual App Store URL
        if let url = URL(string: "https://apps.apple.com/app/id1234567890") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        UpdateView()
    }
}



