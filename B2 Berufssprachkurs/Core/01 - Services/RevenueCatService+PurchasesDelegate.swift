//
//  RevenueCatService+PurchasesDelegate.swift
//  B2 Berufssprachkurs
//

import RevenueCat

extension RevenueCatService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            await updateCustomerInfo(customerInfo)
        }
    }

    nonisolated func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        startPurchase { [weak self] _, customerInfo, _, _ in
            if let customerInfo = customerInfo {
                Task { @MainActor [weak self] in
                    await self?.updateCustomerInfo(customerInfo)
                }
            }
        }
    }
}
