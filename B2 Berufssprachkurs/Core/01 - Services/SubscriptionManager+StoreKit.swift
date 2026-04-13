//
//  SubscriptionManager+StoreKit.swift
//  B2 Berufssprachkurs
//
//  StoreKit integration helpers used by SubscriptionManager.
//  Created: 06.04.26.
//

import Foundation
import RevenueCat
import StoreKit

// MARK: - SubscriptionManager

extension SubscriptionManager {
    struct StoreKitEntitlementSnapshot {
        var hasActiveSubscription: Bool
        var activeProductID: String?
        var expirationDate: Date?
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let offerings = try await revenueCatService.getOfferings()

            var productsDict: [String: Product] = [:]

            if let currentOffering = offerings.current {
                for package in currentOffering.availablePackages {
                    let storeProduct = package.storeProduct
                    if let product = try? await Product.products(for: [storeProduct.productIdentifier]).first {
                        productsDict[storeProduct.productIdentifier] = product
                    } else {
                        print("SubscriptionManager: Could not load StoreKit Product for \(storeProduct.productIdentifier)")
                    }
                }
            }

            let directProducts = try await Product.products(for: productIDs)
            for product in directProducts {
                if productsDict[product.id] == nil {
                    productsDict[product.id] = product
                }
            }

            self.products = productsDict

            await checkSubscriptionStatus()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("SubscriptionManager: Error loading products - \(error)")

            do {
                let loadedProducts = try await Product.products(for: productIDs)
                var productsDict: [String: Product] = [:]
                for product in loadedProducts {
                    productsDict[product.id] = product
                }
                self.products = productsDict
            } catch {
                print("SubscriptionManager: Fallback StoreKit loading also failed - \(error)")
            }
        }

        isLoading = false
    }

    func checkSubscriptionStatus() async {
        await revenueCatService.syncCustomerInfo()
        let storeKit = await currentStoreKitEntitlementSnapshot()
        applyMergedEntitlementState(
            revenueCatPremium: revenueCatService.isPremiumActive,
            revenueCatProductID: revenueCatService.activeProductID,
            storeKit: storeKit
        )
    }

    func currentStoreKitEntitlementSnapshot() async -> StoreKitEntitlementSnapshot {
        var hasStoreKitSubscription = false
        var storeKitProductID: String?
        var storeKitExpiration: Date?

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                guard productIDs.contains(transaction.productID) else { continue }

                hasStoreKitSubscription = true

                if storeKitProductID == nil {
                    storeKitProductID = transaction.productID
                }

                if let exp = transaction.expirationDate {
                    if let current = storeKitExpiration {
                        if exp > current {
                            storeKitExpiration = exp
                        }
                    } else {
                        storeKitExpiration = exp
                    }
                }
            } catch {
                print("SubscriptionManager: Error verifying transaction - \(error)")
            }
        }

        return StoreKitEntitlementSnapshot(
            hasActiveSubscription: hasStoreKitSubscription,
            activeProductID: storeKitProductID,
            expirationDate: storeKitExpiration
        )
    }

    func purchaseSubscription(productID: String? = nil) async throws {
        let targetProductID = productID ?? PaywallProductID.monthly.rawValue

        purchaseState = .purchasing

        do {
            _ = try await revenueCatService.purchase(productIdentifier: targetProductID)

            await updateFromRevenueCat()
            purchaseState = .success

            await checkSubscriptionStatus()

        } catch RevenueCatError.userCancelled {
            purchaseState = .idle
            throw SubscriptionError.userCancelled
        } catch {
            guard let product = products[targetProductID] else {
                purchaseState = .failed("Product not available")
                throw SubscriptionError.productNotLoaded
            }

            do {
                let result = try await product.purchase()

                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)

                    hasActiveSubscription = true
                    isPremiumActive = true
                    purchaseState = .success

                    await transaction.finish()

                    await checkSubscriptionStatus()

                case .userCancelled:
                    purchaseState = .idle
                    throw SubscriptionError.userCancelled

                case .pending:
                    purchaseState = .loading

                @unknown default:
                    purchaseState = .failed("Unknown purchase result")
                    throw SubscriptionError.unknown
                }
            } catch {
                purchaseState = .failed(error.localizedDescription)
                errorMessage = error.localizedDescription
                throw error
            }
        }
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        restoreFeedbackMessage = nil
        showRestoreFeedbackAlert = false

        do {
            try await revenueCatService.restorePurchases()
            await checkSubscriptionStatus()
        } catch {
            print("SubscriptionManager: RevenueCat restore failed, trying StoreKit - \(error)")
            await checkSubscriptionStatus()
        }

        isLoading = false

        if isPremiumActive {
            HapticManager.shared.success()
            restoreFeedbackMessage = Localizable.string(Localizable.restoreSuccessActiveSubscription)
            showRestoreFeedbackAlert = true
        } else {
            errorMessage = Localizable.string(Localizable.restoreFailedNoActiveSubscription)
            restoreFeedbackMessage = Localizable.string(Localizable.restoreFailedNoActiveSubscription)
            showRestoreFeedbackAlert = true
            HapticManager.shared.warning()
        }
    }

    func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.transactionUnverified
        case .verified(let safe):
            return safe
        }
    }
}
