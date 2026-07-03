//
//  SavedToICloudSettingsMock.swift
//  B2 Berufssprachkurs
//
//  Visual replica of Settings → iCloud → Saved to iCloud for in-app guidance.
//  Created: 03.07.26.
//

import SwiftUI
import UIKit

// MARK: - Layout

private enum SavedToICloudMockLayout {
    static let screenCornerRadius: CGFloat = 20
    static let sectionCornerRadius: CGFloat = 26
    static let navigationBarHeight: CGFloat = 44
    static let backButtonSize: CGFloat = 34
    static let appIconSize: CGFloat = 29
    static let appIconCornerRadius: CGFloat = 6.5
    static let cloudIconSize: CGFloat = 60
    static let cloudIconCornerRadius: CGFloat = 13
    static let horizontalInset: CGFloat = 16
}

// MARK: - Style

private enum SavedToICloudMockStyle {
    static var appleBlueGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.30, blue: 0.82),
                Color(red: 0.22, green: 0.55, blue: 0.98),
                Color(red: 0.40, green: 0.72, blue: 1.00),
            ],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }
}

// MARK: - Mock Screen

struct SavedToICloudSettingsMock: View {
    let appDisplayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            mockNavigationBar
            savedToICloudHeaderSection
            appToggleSection
        }
        .padding(.bottom, SavedToICloudMockLayout.horizontalInset)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: SavedToICloudMockLayout.screenCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SavedToICloudMockLayout.screenCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var mockNavigationBar: some View {
        ZStack {
            HStack {
                mockBackButton
                Spacer(minLength: 0)
            }
            .padding(.horizontal, SavedToICloudMockLayout.horizontalInset)

            Text(Localizable.string(Localizable.iCloud))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(height: SavedToICloudMockLayout.navigationBarHeight)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var mockBackButton: some View {
        ZStack {
            Circle()
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                }

            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(
            width: SavedToICloudMockLayout.backButtonSize,
            height: SavedToICloudMockLayout.backButtonSize
        )
    }

    private var savedToICloudHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            cloudIconTile

            VStack(alignment: .leading, spacing: 4) {
                Text(Localizable.string(Localizable.iCloudSavedToICloudTitle))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text(Localizable.string(Localizable.iCloudSavedToICloudSubtitle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: SavedToICloudMockLayout.sectionCornerRadius, style: .continuous))
        .padding(.horizontal, SavedToICloudMockLayout.horizontalInset)
    }

    private var cloudIconTile: some View {
        let tileShape = RoundedRectangle(
            cornerRadius: SavedToICloudMockLayout.cloudIconCornerRadius,
            style: .continuous
        )

        return ZStack {
            tileShape
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 1.5, x: 0, y: 1)

            tileShape
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)

            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill")
                .font(.system(size: 28, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(SavedToICloudMockStyle.appleBlueGradient)
        }
        .frame(
            width: SavedToICloudMockLayout.cloudIconSize,
            height: SavedToICloudMockLayout.cloudIconSize
        )
    }

    private var appToggleSection: some View {
        HStack(spacing: 12) {
            appIconView
                .frame(
                    width: SavedToICloudMockLayout.appIconSize,
                    height: SavedToICloudMockLayout.appIconSize
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: SavedToICloudMockLayout.appIconCornerRadius,
                        style: .continuous
                    )
                )

            Text(appDisplayName)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Toggle("", isOn: .constant(true))
                .labelsHidden()
                .tint(.green)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: SavedToICloudMockLayout.sectionCornerRadius, style: .continuous))
        .padding(.horizontal, SavedToICloudMockLayout.horizontalInset)
    }

    @ViewBuilder
    private var appIconView: some View {
        if let uiImage = BundleAppIcon.image {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image("Mascot")
                .resizable()
                .scaledToFill()
        }
    }
}

// MARK: - App Icon

private enum BundleAppIcon {
    static var image: UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let iconName = files.last,
           let image = UIImage(named: iconName) {
            return image
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    SavedToICloudSettingsMock(appDisplayName: "Hero B2")
        .padding()
        .background(Color(.systemGroupedBackground))
}
