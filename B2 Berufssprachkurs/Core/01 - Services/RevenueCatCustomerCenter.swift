//
//  RevenueCatCustomerCenter.swift
//  B2 Berufssprachkurs
//
//  Customer Center Integration Helper
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// Helper for presenting RevenueCat Customer Center
@MainActor
struct RevenueCatCustomerCenter {
    
    /// Presents the Customer Center modally using UIKit
    /// - Parameter presentingViewController: The view controller to present from
    static func present(from presentingViewController: UIViewController) {
        // Create a SwiftUI CustomerCenterView wrapped in UIHostingController
        let customerCenterView = CustomerCenterView()
        let hostingController = UIHostingController(rootView: customerCenterView)
        
        // Configure navigation
        let navController = UINavigationController(rootViewController: hostingController)
        navController.navigationBar.prefersLargeTitles = false
        
        // Present the customer center
        presentingViewController.present(navController, animated: true, completion: nil)
    }
    
    /// Presents the Customer Center from a SwiftUI view
    /// - Parameter isPresented: Binding to control presentation
    /// Note: This method is kept for compatibility but should use the SwiftUI sheet modifier instead
    static func present(isPresented: Binding<Bool>) {
        // This method is deprecated - use .sheet(isPresented:) with CustomerCenterView() directly
        // Keeping for backward compatibility but it won't work properly
        // Use: .sheet(isPresented: $showCustomerCenter) { CustomerCenterView() }
        print("⚠️ RevenueCatCustomerCenter.present(isPresented:) is deprecated. Use .sheet(isPresented:) with CustomerCenterView() directly.")
    }
}

// MARK: - SwiftUI Customer Center View

/// SwiftUI view wrapper for RevenueCat Customer Center
struct CustomerCenterView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            RevenueCatUI.CustomerCenterView()
                .navigationTitle("Manage Subscription")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - SwiftUI Customer Center View Modifier

struct CustomerCenterModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                CustomerCenterView()
            }
    }
}

extension View {
    /// Presents RevenueCat Customer Center when binding is true
    /// Usage: .customerCenter(isPresented: $showCustomerCenter)
    func customerCenter(isPresented: Binding<Bool>) -> some View {
        self.modifier(CustomerCenterModifier(isPresented: isPresented))
    }
}
