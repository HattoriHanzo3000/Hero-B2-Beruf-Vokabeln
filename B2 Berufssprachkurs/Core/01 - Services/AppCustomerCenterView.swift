//
//  AppCustomerCenterView.swift
//  B2 Berufssprachkurs
//
//  Wrapper view for presenting RevenueCat Customer Center in-app.
//  Created: 05.04.26.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

// MARK: - View

/// App wrapper for `RevenueCatUI.CustomerCenterView`: navigation chrome, localized title, dismiss.
struct AppCustomerCenterView: View {
    // MARK: State

    @Environment(\.dismiss) private var dismiss

    // MARK: View Layout

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
