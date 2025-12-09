//
//  UpdateView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit

struct UpdateView: View {
    @State private var latestVersion: String = "1.0"
    @State private var hasUpdate: Bool = false
    @State private var availableVersionReleaseNotes: String? = nil
    @State private var isLoadingUpdateInfo: Bool = false
    
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var versionDescription: String? {
        if let updateFeatures = UpdateFeaturesConfig.getFeatures(for: currentVersion),
           !updateFeatures.isEmpty {
            let combinedFeatures = combineFeatures(updateFeatures)
            if !combinedFeatures.isEmpty {
                return "\(Localizable.string(Localizable.thisUpdateAdds)) \(combinedFeatures)"
            }
        }
        return nil
    }
    
    /// Combines feature list into a single flowing text without bullets
    private func combineFeatures(_ features: [String]) -> String {
        // Remove any existing bullets and clean up
        let cleaned = features.map { feature in
            feature
                .replacingOccurrences(of: "•", with: "")
                .replacingOccurrences(of: "-", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }
        
        // Handle empty array
        guard !cleaned.isEmpty else {
            return ""
        }
        
        // Join with commas and "and" for the last item
        if cleaned.count == 1 {
            return cleaned[0]
        } else if cleaned.count == 2 {
            return "\(cleaned[0]) and \(cleaned[1])"
        } else {
            let allButLast = cleaned.dropLast().joined(separator: ", ")
            if let last = cleaned.last {
                return "\(allButLast), and \(last)"
            }
            return allButLast
        }
    }
    
    var body: some View {
        List {
            SwiftUI.Section {
                versionCard(
                    title: "\(Localizable.string(Localizable.version)) \(currentVersion)",
                    description: versionDescription ?? ""
                )
            }
            
            if hasUpdate {
                SwiftUI.Section {
                    versionCard(
                        title: "\(Localizable.string(Localizable.version)) \(latestVersion)",
                        description: Localizable.string(Localizable.newVersionAvailable)
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
                
                if !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description.isEmpty ? "" : description)
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
        Task {
            await fetchUpdateInfo()
        }
    }
    
    @MainActor
    private func fetchUpdateInfo() async {
        isLoadingUpdateInfo = true
        defer { isLoadingUpdateInfo = false }
        
        do {
            if let appInfo = try await AppStoreService.shared.fetchAppInfo() {
                let storeVersion = appInfo.version
                latestVersion = storeVersion
                
                // Compare versions to determine if update is available
                if compareVersions(currentVersion, storeVersion) < 0 {
                    hasUpdate = true
                    
                    // Fetch and format release notes
                    if let releaseNotes = appInfo.releaseNotes {
                        availableVersionReleaseNotes = AppStoreService.shared.formatReleaseNotes(releaseNotes)
                    }
                } else {
                    hasUpdate = false
                }
            }
        } catch {
            // Silently fail - if we can't fetch, just don't show update
            print("Failed to fetch update info: \(error.localizedDescription)")
            hasUpdate = false
        }
    }
    
    /// Compares two version strings
    /// Returns: -1 if version1 < version2, 0 if equal, 1 if version1 > version2
    private func compareVersions(_ version1: String, _ version2: String) -> Int {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0
            
            if v1Value < v2Value {
                return -1
            } else if v1Value > v2Value {
                return 1
            }
        }
        
        return 0
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



