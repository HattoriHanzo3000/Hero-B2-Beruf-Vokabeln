//
//  AppLog.swift
//  B2 Berufssprachkurs
//
//  Shared OSLog categories used across app subsystems.
//  Created: 05.04.26.
//

import OSLog

// MARK: - Loggers

enum AppLog {
    static let subscription = Logger(subsystem: Bundle.main.bundleIdentifier ?? "B2Berufssprachkurs", category: "subscription")
    static let pdf = Logger(subsystem: Bundle.main.bundleIdentifier ?? "B2Berufssprachkurs", category: "pdf")
    static let appUpdate = Logger(subsystem: Bundle.main.bundleIdentifier ?? "B2Berufssprachkurs", category: "appUpdate")
}
