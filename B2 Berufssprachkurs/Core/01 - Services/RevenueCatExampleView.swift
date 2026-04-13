//
//  RevenueCatExampleView.swift
//  B2 Berufssprachkurs
//
//  Demo view showcasing RevenueCat integration behavior.
//  Created: 17.12.25.
//

import SwiftUI
import RevenueCat

/// Example view demonstrating RevenueCat integration
struct RevenueCatExampleView: View {
    @StateObject private var revenueCatService = RevenueCatService.shared
    @State private var showPaywall = false
    @State private var showCustomerCenter = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            // Premium Status Section
            SwiftUI.Section(header: Text("Premium Status")) {
                HStack {
                    Text("Premium Active")
                    Spacer()
                    if revenueCatService.isPremiumActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                if let expirationDate = revenueCatService.premiumExpirationDate {
                    HStack {
                        Text("Expires")
                        Spacer()
                        Text(expirationDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let productID = revenueCatService.activeProductID {
                    HStack {
                        Text("Product")
                        Spacer()
                        Text(productID)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            // Actions Section
            SwiftUI.Section(header: Text("Actions")) {
                Button(action: {
                    showPaywall = true
                }) {
                    Label("Upgrade to Premium", systemImage: "crown.fill")
                }
                .disabled(revenueCatService.isPremiumActive)
                
                Button(action: {
                    showCustomerCenter = true
                }) {
                    Label("Manage Subscription", systemImage: "person.circle")
                }
                
                Button(action: {
                    Task {
                        await restorePurchases()
                    }
                }) {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
            }
            
            // Offerings Section
            if let offering = revenueCatService.currentOffering {
                SwiftUI.Section(header: Text("Available Packages")) {
                    ForEach(offering.availablePackages, id: \.identifier) { package in
                        PackageRow(package: package)
                    }
                }
            }
            
            // Debug Section
            #if DEBUG
            SwiftUI.Section(header: Text("Debug")) {
                Button(action: {
                    revenueCatService.printCustomerInfo()
                }) {
                    Label("Print Customer Info", systemImage: "info.circle")
                }
                
                Button(action: {
                    Task {
                        await revenueCatService.syncCustomerInfo()
                        await revenueCatService.loadOfferings()
                    }
                }) {
                    Label("Refresh Data", systemImage: "arrow.clockwise")
                }
            }
            #endif
        }
        .navigationTitle("RevenueCat Integration")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showCustomerCenter) {
            AppCustomerCenterView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            // Load offerings on appear
            if revenueCatService.currentOffering == nil {
                await revenueCatService.loadOfferings()
            }
        }
    }
    
    private func restorePurchases() async {
        do {
            try await revenueCatService.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Package Row

struct PackageRow: View {
    let package: Package
    @ObservedObject private var revenueCatService = RevenueCatService.shared
    @State private var isPurchasing = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.storeProduct.localizedTitle)
                    .font(.headline)
                
                Text(package.storeProduct.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(package.storeProduct.localizedPriceString)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            if isPurchasing {
                ProgressView()
            } else {
                Button("Purchase") {
                    Task {
                        await purchasePackage()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(revenueCatService.isPremiumActive)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func purchasePackage() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let (_, _) = try await revenueCatService.purchase(package: package)
            // Purchase successful - RevenueCatService will update automatically
        } catch RevenueCatError.userCancelled {
            // User cancelled - no error needed
        } catch {
            print("Purchase error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        RevenueCatExampleView()
    }
}
