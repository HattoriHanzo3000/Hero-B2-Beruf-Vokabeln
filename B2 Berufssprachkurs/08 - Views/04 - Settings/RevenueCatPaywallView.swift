//
//  RevenueCatPaywallView.swift
//  B2 Berufssprachkurs
//
//  RevenueCat Paywall Integration
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// RevenueCat Paywall View using RevenueCatUI
struct RevenueCatPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCatService = RevenueCatService.shared
    @State private var showCustomerCenter = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if revenueCatService.isLoadingOfferings {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if revenueCatService.currentOffering != nil {
                    PaywallView()
                        .onPurchaseCompleted { customerInfo in
                            // Purchase completed successfully
                            handlePurchaseCompleted(customerInfo)
                        }
                        .onPurchaseFailure { error in
                            // Purchase failed
                            handlePurchaseFailure(error)
                        }
                        .onRestoreCompleted { customerInfo in
                            // Restore completed
                            handleRestoreCompleted(customerInfo)
                        }
                        .onRestoreFailure { error in
                            // Restore failed
                            handleRestoreFailure(error)
                        }
                        .onRequestedDismissal {
                            // Handle dismissal request
                            dismiss()
                        }
                } else {
                    // No offering available - show fallback
                    noOfferingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showCustomerCenter = true
                    }) {
                        Text("Manage")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showCustomerCenter) {
                CustomerCenterView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .task {
            // Load offerings if not already loaded
            if revenueCatService.currentOffering == nil {
                await revenueCatService.loadOfferings()
            }
        }
        .onChange(of: revenueCatService.isPremiumActive) { _, isActive in
            if isActive {
                // Premium activated, dismiss paywall
                dismiss()
            }
        }
    }
    
    // MARK: - Fallback View
    
    private var noOfferingView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No Subscription Options Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please check your internet connection and try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await revenueCatService.loadOfferings()
                }
            }) {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Purchase Handlers
    
    private func handlePurchaseCompleted(_ customerInfo: CustomerInfo) {
        print("✅ Purchase completed successfully")
        // RevenueCatService will automatically update via delegate
        // Check if premium is now active
        if revenueCatService.isPremiumActive {
            dismiss()
        }
    }
    
    private func handlePurchaseFailure(_ error: Error) {
        print("❌ Purchase failed: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
        showError = true
    }
    
    private func handleRestoreCompleted(_ customerInfo: CustomerInfo) {
        print("✅ Restore completed successfully")
        // RevenueCatService will automatically update via delegate
        if revenueCatService.isPremiumActive {
            dismiss()
        }
    }
    
    private func handleRestoreFailure(_ error: Error) {
        print("❌ Restore failed: \(error.localizedDescription)")
        errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        showError = true
    }
}

// MARK: - Preview

#Preview {
    RevenueCatPaywallView()
}
