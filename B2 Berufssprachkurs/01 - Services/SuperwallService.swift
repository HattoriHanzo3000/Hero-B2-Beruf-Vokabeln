//
//  SuperwallService.swift
//  B2 Berufssprachkurs
//
//  Superwall + RevenueCat Integration
//

import Foundation
import Combine
import SuperwallKit
import RevenueCat

/// Service to handle Superwall initialization and RevenueCat integration
@MainActor
final class SuperwallService: NSObject, ObservableObject {
    static let shared = SuperwallService()
    
    // MARK: - Published Properties
    
    @Published var isInitialized = false
    @Published var isConfigured = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let revenueCatService = RevenueCatService.shared
    
    // MARK: - Configuration
    
    /// Superwall API Key - Retrieved from AppConfig for secure management
    /// Dashboard: https://superwall.com/dashboard → Settings → API Keys
    private var apiKey: String {
        AppConfig.superwallAPIKey
    }
    
    // MARK: - RevenueCat Integration Note
    //
    // To forward subscription events from RevenueCat to Superwall:
    // 1. Go to RevenueCat Dashboard: https://app.revenuecat.com
    // 2. Navigate to: Project Settings → Integrations → Superwall
    // 3. Add your RevenueCat Public API Key: pk_a1ff69eaf4ea6e199bcabdcfbd17d39fc8679f426b8f2ca5
    // 4. This enables RevenueCat to automatically forward purchase/renewal events to Superwall
    // 
    // Note: This is configured in the RevenueCat dashboard, NOT in this code file.
    // The app code already uses RevenueCat as the purchase controller (see RevenueCatPurchaseController below).
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Configuration
    
    /// Configures Superwall with RevenueCat integration
    func configure() {
        // Prevent double initialization
        guard !isConfigured else {
            print("ℹ️ SuperwallService: Already configured, skipping...")
            return
        }
        
        guard !apiKey.contains("YOUR_") else {
            print("⚠️ SuperwallService: API key not configured. Please add your Superwall API key.")
            errorMessage = "Superwall API key not configured"
            return
        }
        
        guard revenueCatService.isInitialized else {
            print("⚠️ SuperwallService: RevenueCat not initialized. Waiting...")
            // Wait for RevenueCat to initialize
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if revenueCatService.isInitialized && !isConfigured {
                    await configureSuperwall()
                }
            }
            return
        }
        
        Task {
            await configureSuperwall()
        }
    }
    
    private func configureSuperwall() async {
        // Create purchase controller that uses RevenueCat
        let purchaseController = RevenueCatPurchaseController(revenueCatService: revenueCatService)
        
        // Configure Superwall with API key and purchase controller
        Superwall.configure(
            apiKey: apiKey,
            purchaseController: purchaseController
        )
        
        // Set delegate to receive Superwall events
        Superwall.shared.delegate = self
        
        isConfigured = true
        isInitialized = true
        
        // Sync subscription status
        await syncSubscriptionStatus()
        
        print("✅ SuperwallService: Superwall configured successfully with RevenueCat integration")
    }
    
    // MARK: - Subscription Status Sync
    
    /// Syncs subscription status between RevenueCat and Superwall
    func syncSubscriptionStatus() async {
        guard isConfigured else {
            print("⚠️ SuperwallService: Cannot sync - Superwall not configured")
            return
        }
        
        // Get latest customer info from RevenueCat
        await revenueCatService.syncCustomerInfo()
        
        // Update Superwall with subscription status
        let hasActiveSubscription = revenueCatService.isPremiumActive
        
        // Set subscription status in Superwall (using property, not method)
        if hasActiveSubscription {
            // Get active entitlements from RevenueCat and convert to Superwall Entitlement type
            let revenueCatEntitlements = revenueCatService.activeEntitlements
            let superwallEntitlements = Set(revenueCatEntitlements.map { SuperwallKit.Entitlement(id: $0) })
            Superwall.shared.subscriptionStatus = .active(superwallEntitlements)
        } else {
            Superwall.shared.subscriptionStatus = .inactive
        }
        
        print("✅ SuperwallService: Subscription status synced - Active: \(hasActiveSubscription)")
    }
    
    // MARK: - Paywall Presentation
    
    /// Registers a placement that can trigger a paywall
    /// - Parameters:
    ///   - placement: The placement identifier to register
    ///   - feature: Closure to execute if paywall is dismissed or user subscribes
    func register(placement: String, feature: @escaping () -> Void = {}) {
        guard isConfigured else {
            print("⚠️ SuperwallService: Cannot register placement - Superwall not configured")
            return
        }
        
        Superwall.shared.register(placement: placement, feature: feature)
    }
    
    /// Presents a paywall for a specific placement
    /// - Parameters:
    ///   - placement: The placement identifier
    ///   - feature: Closure to execute if paywall is dismissed or user subscribes
    func presentPaywall(placement: String, feature: @escaping () -> Void = {}) {
        guard isConfigured else {
            print("⚠️ SuperwallService: Cannot present paywall - Superwall not configured")
            return
        }
        
        Superwall.shared.register(placement: placement, feature: feature)
    }
    
    /// Presents a paywall with a specific identifier (legacy method name)
    /// - Parameter identifier: The paywall/placement identifier
    @available(*, deprecated, renamed: "presentPaywall(placement:feature:)")
    func presentPaywall(identifier: String) {
        presentPaywall(placement: identifier)
    }
    
    /// Resets the user's subscription status (for testing)
    func reset() {
        Superwall.shared.reset()
        print("✅ SuperwallService: Reset completed")
    }
}

// MARK: - SuperwallDelegate

extension SuperwallService: SuperwallDelegate {
    @MainActor
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        // Sync subscription status for purchase/restore events
        // Using string matching to avoid enum case mismatches
        let eventString = String(describing: eventInfo.event)
        
        if eventString.contains("Complete") || 
           eventString.contains("Start") || 
           eventString.contains("Restore") {
            Task {
                await syncSubscriptionStatus()
            }
        }
        
        // Log the event
        print("📱 Superwall: Event received - \(eventString)")
    }
}

// MARK: - RevenueCat Purchase Controller

/// Purchase controller that integrates RevenueCat with Superwall
@MainActor
final class RevenueCatPurchaseController: PurchaseController {
    private let revenueCatService: RevenueCatService
    
    init(revenueCatService: RevenueCatService) {
        self.revenueCatService = revenueCatService
    }
    
    // MARK: - PurchaseController Protocol
    
    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            // Find the package in RevenueCat offerings
            guard let offering = try? await revenueCatService.getCurrentOffering() else {
                return .failed(PurchaseError.productNotFound)
            }
            
            // Try to find package by product identifier
            var package: Package?
            
            // First, try to find by package identifier
            if let foundPackage = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == product.productIdentifier }) {
                package = foundPackage
            } else {
                // If not found, try to find by matching product ID
                package = offering.availablePackages.first { $0.storeProduct.productIdentifier == product.productIdentifier }
            }
            
            guard let targetPackage = package else {
                return .failed(PurchaseError.productNotFound)
            }
            
            // Purchase through RevenueCat
            let (_, userCancelled) = try await revenueCatService.purchase(package: targetPackage)
            
            if userCancelled {
                return .cancelled
            }
            
            // Sync subscription status after purchase
            await syncSubscriptionStatus()
            
            // Check if purchase was successful (has active entitlement)
            if revenueCatService.isPremiumActive {
                return .purchased
            } else {
                return .failed(PurchaseError.purchaseFailed("Purchase completed but entitlement not active"))
            }
            
        } catch RevenueCatError.userCancelled {
            return .cancelled
        } catch {
            return .failed(PurchaseError.purchaseFailed(error.localizedDescription))
        }
    }
    
    func restorePurchases() async -> RestorationResult {
        do {
            try await revenueCatService.restorePurchases()
            
            // Sync subscription status after restore
            await syncSubscriptionStatus()
            
            // Check if restore was successful
            if revenueCatService.isPremiumActive {
                return .restored
            } else {
                return .failed(PurchaseError.purchaseFailed("No active subscription found"))
            }
        } catch {
            return .failed(error as Error)
        }
    }
    
    /// Syncs subscription status between RevenueCat and Superwall
    /// This should be called after purchases/restores to keep Superwall in sync
    private func syncSubscriptionStatus() async {
        await revenueCatService.syncCustomerInfo()
        let isActive = revenueCatService.isPremiumActive
        
        // Set subscription status in Superwall (using property, not method)
        if isActive {
            // Get active entitlements from RevenueCat and convert to Superwall Entitlement type
            let revenueCatEntitlements = revenueCatService.activeEntitlements
            let superwallEntitlements = Set(revenueCatEntitlements.map { SuperwallKit.Entitlement(id: $0) })
            Superwall.shared.subscriptionStatus = .active(superwallEntitlements)
        } else {
            Superwall.shared.subscriptionStatus = .inactive
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: Error {
    case productNotFound
    case purchaseFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .productNotFound:
            return "Product not found in RevenueCat offerings"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        }
    }
}
