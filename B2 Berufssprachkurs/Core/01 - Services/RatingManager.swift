//
//  RatingManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Combine
import Foundation
import StoreKit
import UIKit

@MainActor
class RatingManager: ObservableObject {
    static let shared = RatingManager()

    @Published var showRatingPrompt = false

    private let userDefaults = UserDefaults.standard
    private let appLaunchCountKey = "ratingAppLaunchCount"
    private let studySessionCountKey = "ratingStudySessionCount"
    private let lastRatingRequestDateKey = "ratingLastRequestDate"
    private let ratingRequestsThisYearKey = "ratingRequestsThisYear"
    private let ratingDisabledKey = "ratingDisabled"
    private let lastRatingRequestYearKey = "ratingLastRequestYear"

    private let minAppLaunches = 3
    private let minStudySessions = 5
    private let minDaysBetweenRequests = 90
    private let maxRequestsPerYear = 3

    private init() {}

    // MARK: - Public Methods

    func trackAppLaunch() {
        let currentCount = userDefaults.integer(forKey: appLaunchCountKey)
        userDefaults.set(currentCount + 1, forKey: appLaunchCountKey)
    }

    /// Increments study session count. Returns whether the pre-prompt may be shown (caller still gates UI timing).
    func trackStudySession() -> Bool {
        let currentCount = userDefaults.integer(forKey: studySessionCountKey)
        userDefaults.set(currentCount + 1, forKey: studySessionCountKey)
        return shouldShowRatingPrompt()
    }

    func requestRating() {
        guard shouldShowRatingPrompt() else { return }
        showRatingPrompt = true
    }

    func requestAppReview() {
        updateRatingRequestDate()

        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: windowScene)
            } else {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }

        showRatingPrompt = false
    }

    func remindLater() {
        showRatingPrompt = false
    }

    func disableRatingRequests() {
        userDefaults.set(true, forKey: ratingDisabledKey)
        showRatingPrompt = false
    }

    // MARK: - Private Methods

    private func shouldShowRatingPrompt() -> Bool {
        if userDefaults.bool(forKey: ratingDisabledKey) {
            return false
        }

        let appLaunches = userDefaults.integer(forKey: appLaunchCountKey)
        let studySessions = userDefaults.integer(forKey: studySessionCountKey)
        guard appLaunches >= minAppLaunches && studySessions >= minStudySessions else {
            return false
        }

        if let lastRequestDate = userDefaults.object(forKey: lastRatingRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= minDaysBetweenRequests else {
                return false
            }
        }

        syncYearlyRequestCounterIfCalendarYearChanged()
        let requestsThisYear = userDefaults.integer(forKey: ratingRequestsThisYearKey)
        guard requestsThisYear < maxRequestsPerYear else {
            return false
        }

        return true
    }

    /// When the calendar year changes, reset the per-year counter so eligibility matches `incrementRequestsThisYearForNewRequest()`.
    private func syncYearlyRequestCounterIfCalendarYearChanged() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let storedYear = userDefaults.integer(forKey: lastRatingRequestYearKey)
        guard storedYear != currentYear else { return }
        userDefaults.set(0, forKey: ratingRequestsThisYearKey)
        userDefaults.set(currentYear, forKey: lastRatingRequestYearKey)
    }

    private func updateRatingRequestDate() {
        userDefaults.set(Date(), forKey: lastRatingRequestDateKey)
        incrementRequestsThisYearForNewRequest()
    }

    private func incrementRequestsThisYearForNewRequest() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let storedYear = userDefaults.integer(forKey: lastRatingRequestYearKey)
        if storedYear == currentYear {
            let n = userDefaults.integer(forKey: ratingRequestsThisYearKey)
            userDefaults.set(n + 1, forKey: ratingRequestsThisYearKey)
        } else {
            userDefaults.set(1, forKey: ratingRequestsThisYearKey)
            userDefaults.set(currentYear, forKey: lastRatingRequestYearKey)
        }
    }
}
