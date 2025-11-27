//
//  PromoCodeManager.swift
//  B2 Berufssprachkurs
//
//  Created for promo code feature
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PromoCodeManager: ObservableObject {
    static let shared = PromoCodeManager()
    
    // Valid promo codes (you can also fetch these from a server)
    private let validPromoCodes: Set<String> = [
        "WIRSCHAFFENDAS",
        // Add more promo codes here
    ]
    
    @Published private(set) var isPremiumActive: Bool {
        didSet {
            UserDefaults.standard.set(isPremiumActive, forKey: "promoCodePremiumActive")
        }
    }
    
    private var redeemedPromoCodesData: Data {
        get {
            UserDefaults.standard.data(forKey: "redeemedPromoCodes") ?? Data()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "redeemedPromoCodes")
        }
    }
    
    private var redeemedPromoCodes: Set<String> {
        get {
            if let codes = try? JSONDecoder().decode(Set<String>.self, from: redeemedPromoCodesData) {
                return codes
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                redeemedPromoCodesData = data
            }
        }
    }
    
    private init() {
        // Load premium status from UserDefaults
        self.isPremiumActive = UserDefaults.standard.bool(forKey: "promoCodePremiumActive")
    }
    
    func redeemPromoCode(_ code: String) -> (success: Bool, message: String) {
        let upperCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if already redeemed
        if redeemedPromoCodes.contains(upperCode) {
            return (false, "This promo code has already been redeemed")
        }
        
        // Check if valid
        if validPromoCodes.contains(upperCode) {
            redeemedPromoCodes.insert(upperCode)
            isPremiumActive = true
            return (true, "Promo code redeemed successfully! Ads are now disabled.")
        }
        
        return (false, "Invalid promo code")
    }
    
    func clearPromoCodes() {
        redeemedPromoCodes.removeAll()
        isPremiumActive = false
    }
}

