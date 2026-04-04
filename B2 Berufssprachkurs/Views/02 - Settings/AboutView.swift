//
//  AboutView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    #if DEBUG
    @State private var versionTapCount = 0
    @State private var showDebugSheet = false
    #endif

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var aboutDescriptionText: Text {
        Text(Localizable.string(Localizable.aboutThisApp))
            .fontWeight(.bold)
            .italic()
            + Text(Localizable.string(Localizable.aboutAppDescLead))
            + Text(Localizable.string(Localizable.aboutOfficialTestName))
                .fontWeight(.bold)
                .italic()
            + Text(Localizable.string(Localizable.aboutAppDescMid))
            + Text(Localizable.string(Localizable.aboutOfficialBookTitle))
                .fontWeight(.bold)
                .italic()
            + Text(Localizable.string(Localizable.aboutAppDescTail))
    }

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

                    aboutDescriptionText
                        .font(.body)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Text("\(Localizable.string(Localizable.version)) \(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        #if DEBUG
                        .onTapGesture {
                            versionTapCount += 1
                            if versionTapCount >= AboutDebugGesture.requiredTapsToRevealSheet {
                                versionTapCount = 0
                                HapticManager.shared.mediumImpact()
                                showDebugSheet = true
                            }
                        }
                        #endif
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
        .navigationTitle(Localizable.string(Localizable.about))
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .sheet(isPresented: $showDebugSheet) {
            AboutDebugSheet(
                dataService: dataService,
                subscriptionManager: subscriptionManager
            )
        }
        #endif
    }
}

#if DEBUG
private enum AboutDebugGesture {
    static let requiredTapsToRevealSheet = 7
}
#endif

#Preview {
    NavigationStack {
        AboutView()
            .environmentObject(DataService())
    }
}
