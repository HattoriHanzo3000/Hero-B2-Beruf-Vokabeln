//
//  RatingManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation
import StoreKit
import SwiftUI
import UIKit
import Combine

@MainActor
class RatingManager: ObservableObject {
    static let shared = RatingManager()
    
    @Published var showRatingPrompt = false
    
    // UserDefaults keys
    private let userDefaults = UserDefaults.standard
    private let appLaunchCountKey = "ratingAppLaunchCount"
    private let studySessionCountKey = "ratingStudySessionCount"
    private let lastRatingRequestDateKey = "ratingLastRequestDate"
    private let ratingRequestsThisYearKey = "ratingRequestsThisYear"
    private let ratingDisabledKey = "ratingDisabled"
    private let lastRatingRequestYearKey = "ratingLastRequestYear"
    
    // Thresholds (iOS best practices)
    private let minAppLaunches = 3
    private let minStudySessions = 5
    private let minDaysBetweenRequests = 90 // Apple's recommendation
    private let maxRequestsPerYear = 3 // Apple's limit
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Call this when app launches to track usage
    func trackAppLaunch() {
        let currentCount = userDefaults.integer(forKey: appLaunchCountKey)
        userDefaults.set(currentCount + 1, forKey: appLaunchCountKey)
    }
    
    /// Call this after completing a study session
    /// Returns true if rating prompt should be shown
    func trackStudySession() -> Bool {
        let currentCount = userDefaults.integer(forKey: studySessionCountKey)
        userDefaults.set(currentCount + 1, forKey: studySessionCountKey)
        
        // Check if we should show the prompt
        return shouldShowRatingPrompt()
    }
    
    /// Manually request rating (e.g., from settings)
    func requestRating() {
        guard shouldShowRatingPrompt() else { return }
        showRatingPrompt = true
    }
    
    /// User tapped "Rate" button - show Apple's native dialog
    func requestAppReview() {
        // Update tracking
        updateRatingRequestDate()
        
        // Request Apple's native review
        // Note: requestReview may not always show the dialog (Apple controls this)
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            if #available(iOS 18.0, *) {
                // Use new iOS 18+ API
                AppStore.requestReview(in: windowScene)
            } else {
                // Fallback to deprecated API for older iOS versions
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
        
        // Dismiss our pre-prompt
        showRatingPrompt = false
    }
    
    /// User tapped "Later" - just dismiss
    func remindLater() {
        showRatingPrompt = false
    }
    
    /// User tapped "No thanks" - disable future requests
    func disableRatingRequests() {
        userDefaults.set(true, forKey: ratingDisabledKey)
        showRatingPrompt = false
    }
    
    // MARK: - Private Methods
    
    private func shouldShowRatingPrompt() -> Bool {
        // Check if user disabled rating requests
        if userDefaults.bool(forKey: ratingDisabledKey) {
            return false
        }
        
        // Check minimum engagement thresholds
        let appLaunches = userDefaults.integer(forKey: appLaunchCountKey)
        let studySessions = userDefaults.integer(forKey: studySessionCountKey)
        
        guard appLaunches >= minAppLaunches && studySessions >= minStudySessions else {
            return false
        }
        
        // Check time since last request
        if let lastRequestDate = userDefaults.object(forKey: lastRatingRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= minDaysBetweenRequests else {
                return false
            }
        }
        
        // Check requests per year limit
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastRequestYear = userDefaults.integer(forKey: lastRatingRequestYearKey)
        
        if lastRequestYear == currentYear {
            let requestsThisYear = userDefaults.integer(forKey: ratingRequestsThisYearKey)
            guard requestsThisYear < maxRequestsPerYear else {
                return false
            }
        } else {
            // New year, reset counter
            userDefaults.set(0, forKey: ratingRequestsThisYearKey)
            userDefaults.set(currentYear, forKey: lastRatingRequestYearKey)
        }
        
        return true
    }
    
    private func updateRatingRequestDate() {
        let now = Date()
        userDefaults.set(now, forKey: lastRatingRequestDateKey)
        
        // Update requests per year counter
        let currentYear = Calendar.current.component(.year, from: now)
        let lastRequestYear = userDefaults.integer(forKey: lastRatingRequestYearKey)
        
        if lastRequestYear == currentYear {
            let currentCount = userDefaults.integer(forKey: ratingRequestsThisYearKey)
            userDefaults.set(currentCount + 1, forKey: ratingRequestsThisYearKey)
        } else {
            userDefaults.set(1, forKey: ratingRequestsThisYearKey)
            userDefaults.set(currentYear, forKey: lastRatingRequestYearKey)
        }
    }
}

