//
//  AdvertisementView.swift
//  B2 Berufssprachkurs
//
//  Sheet for cockpit “More from Hero” — paywall-style green gradient. The Einbürgerungstest app icon is
//  loaded from the App Store (iTunes Lookup + AsyncImage), not from a bundled catalog image.
//

import StoreKit
import SwiftUI
import UIKit

private extension UIApplication {
    /// Foreground window scene → key window → topmost presenter (modals, nav, tab).
    @MainActor
    var b2_topMostViewController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let windowScene = scene else { return nil }
        let window = windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first
        guard let root = window?.rootViewController else { return nil }
        return Self.b2_resolveTopMostViewController(from: root)
    }

    private static func b2_resolveTopMostViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return b2_resolveTopMostViewController(from: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return b2_resolveTopMostViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return b2_resolveTopMostViewController(from: selected)
        }
        return root
    }
}

private enum HeroEinburgerungAppStore {
    /// App Store ID for “Hero – Einbürgerungstest” (https://apps.apple.com/app/id6752272685)
    static let productID = NSNumber(value: 6_752_272_685)
    static let iTunesLookupAppID = 6_752_272_685
}

struct AdvertisementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var einburgerungArtworkURL: URL?
    @State private var einburgerungArtworkLookupFinished = false

    var body: some View {
        NavigationStack {
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

                        Button {
                            HeroEinburgerungStorePresentation.present()
                        } label: {
                            VStack(alignment: .center, spacing: 10) {
                                Text(Localizable.string(Localizable.advertisementHeroLeadTitle))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(Localizable.string(Localizable.advertisementHeroLeadSubtitle))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.88))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(
                            "\(Localizable.string(Localizable.advertisementHeroLeadTitle)). \(Localizable.string(Localizable.advertisementHeroLeadSubtitle))"
                        )

                        einburgerungAppRow
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .background(Color.clear)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            einburgerungArtworkURL = await AppStoreArtworkLookup.artworkURL(
                appID: HeroEinburgerungAppStore.iTunesLookupAppID
            )
            einburgerungArtworkLookupFinished = true
        }
    }

    private var einburgerungAppRow: some View {
        Button {
            HeroEinburgerungStorePresentation.present()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                einburgerungAppIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(Localizable.string(Localizable.advertisementEinburgerungAppTitle))
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    Text(Localizable.string(Localizable.advertisementEinburgerungAppSubtitle))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            "\(Localizable.string(Localizable.advertisementEinburgerungAppTitle)). \(Localizable.string(Localizable.advertisementEinburgerungAppSubtitle))"
        )
    }

    private var einburgerungAppIcon: some View {
        EinburgerungAppIconView(
            artworkURL: einburgerungArtworkURL,
            lookupFinished: einburgerungArtworkLookupFinished
        )
    }
}

// MARK: - App Store artwork (iTunes Lookup)

private enum AppStoreArtworkLookup {
    /// Public iTunes Search API — returns the same artwork URLs the App Store uses for the listing.
    static func artworkURL(appID: Int, countryCode: String = "de") async -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: String(appID)),
            URLQueryItem(name: "country", value: countryCode)
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(iTunesLookupResponse.self, from: data)
            guard let first = decoded.results.first else { return nil }
            let string = first.artworkUrl512 ?? first.artworkUrl100 ?? first.artworkUrl60
            guard let s = string, let artworkURL = URL(string: s) else { return nil }
            return artworkURL
        } catch {
            return nil
        }
    }
}

private struct iTunesLookupResponse: Decodable {
    let results: [iTunesLookupAppResult]
}

private struct iTunesLookupAppResult: Decodable {
    let artworkUrl60: String?
    let artworkUrl100: String?
    let artworkUrl512: String?
}

private struct EinburgerungAppIconView: View {
    let artworkURL: URL?
    let lookupFinished: Bool

    private let size: CGFloat = 60
    private let cornerRadius: CGFloat = 13

    var body: some View {
        Group {
            if !lookupFinished {
                ProgressView()
                    .tint(.white.opacity(0.9))
                    .frame(width: size, height: size)
            } else if let artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white.opacity(0.9))
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        einburgerungStoreIconPlaceholder
                    @unknown default:
                        einburgerungStoreIconPlaceholder
                    }
                }
            } else {
                einburgerungStoreIconPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .accessibilityHidden(true)
    }

    /// Shown when lookup fails or image download fails — no local app-icon asset.
    private var einburgerungStoreIconPlaceholder: some View {
        Color.white.opacity(0.14)
    }
}

// MARK: - SKStoreProductViewController (single UIKit modal from topmost VC — no SwiftUI fullScreenCover)

private enum HeroEinburgerungStorePresentation {
    private static var retainedDelegate: EinburgerungStoreProductDelegate?

    /// Presents `SKStoreProductViewController` once from `UIApplication.shared.b2_topMostViewController` after `loadProduct` succeeds.
    @MainActor
    static func present() {
        guard let presenter = UIApplication.shared.b2_topMostViewController else { return }

        HapticManager.shared.lightImpact()

        let storeVC = SKStoreProductViewController()
        let delegate = EinburgerungStoreProductDelegate {
            retainedDelegate = nil
        }
        retainedDelegate = delegate
        storeVC.delegate = delegate

        let params: [String: Any] = [
            SKStoreProductParameterITunesItemIdentifier: HeroEinburgerungAppStore.productID
        ]
        storeVC.loadProduct(withParameters: params) { loaded, _ in
            DispatchQueue.main.async {
                if loaded {
                    presenter.present(storeVC, animated: true)
                } else {
                    retainedDelegate = nil
                }
            }
        }
    }
}

private final class EinburgerungStoreProductDelegate: NSObject, SKStoreProductViewControllerDelegate {
    private let onTeardown: () -> Void

    init(onTeardown: @escaping () -> Void) {
        self.onTeardown = onTeardown
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true) { [onTeardown] in
            onTeardown()
        }
    }
}

#Preview {
    AdvertisementView()
}
