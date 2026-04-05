//
//  AppCustomerCenterView.swift
//  B2 Berufssprachkurs
//
//  SwiftUI shell around RevenueCat Customer Center (use inside `.sheet`).
//

import RevenueCat
import RevenueCatUI
import SwiftUI

/// App wrapper for `RevenueCatUI.CustomerCenterView`: navigation chrome, localized title, dismiss.
struct AppCustomerCenterView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            RevenueCatUI.CustomerCenterView()
                .navigationTitle(Localizable.string(Localizable.manageSubscription))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(Localizable.string(Localizable.customerCenterDone)) {
                            dismiss()
                        }
                    }
                }
        }
    }
}
