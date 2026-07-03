//
//  ICloudView.swift
//  B2 Berufssprachkurs
//
//  iCloud sync status and setup guidance.
//  Created: 03.07.26.
//

import SwiftUI

// MARK: - Layout

private enum ICloudViewLayout {
    static let statusVerticalPadding: CGFloat = 20
}

// MARK: - Screen

struct ICloudView: View {
    // MARK: State & Environment

    @Environment(\.iCloudSignedInPreview) private var iCloudSignedInPreview

    // MARK: Derived Data

    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Hero B2"
    }

    private var isSignedIn: Bool {
        if let iCloudSignedInPreview {
            return iCloudSignedInPreview
        }
        return FileManager.default.ubiquityIdentityToken != nil
    }

    private var routeInstructions: String {
        String(
            format: Localizable.string(Localizable.iCloudSyncUnavailableInstructions),
            appDisplayName
        )
    }

    // MARK: View Layout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(Localizable.string(Localizable.iCloudSyncFooter))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                statusSection

                Text(routeInstructions)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                SavedToICloudSettingsMock(appDisplayName: appDisplayName)

                Spacer(minLength: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(Localizable.string(Localizable.iCloud))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var statusSection: some View {
        Group {
            if isSignedIn {
                Label {
                    Text(Localizable.string(Localizable.iCloudAccountSignedIn))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "icloud.fill")
                }
                .foregroundStyle(.green)
            } else {
                Label {
                    Text(Localizable.string(Localizable.iCloudSyncUnavailableTitle))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "icloud.slash.fill")
                }
                .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, ICloudViewLayout.statusVerticalPadding)
    }
}

// MARK: - Preview Support

private struct ICloudSignedInPreviewKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    var iCloudSignedInPreview: Bool? {
        get { self[ICloudSignedInPreviewKey.self] }
        set { self[ICloudSignedInPreviewKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview("iCloud — signed in") {
    NavigationStack {
        ICloudView()
            .environment(\.iCloudSignedInPreview, true)
    }
}

#Preview("iCloud — not signed in") {
    NavigationStack {
        ICloudView()
            .environment(\.iCloudSignedInPreview, false)
    }
}
