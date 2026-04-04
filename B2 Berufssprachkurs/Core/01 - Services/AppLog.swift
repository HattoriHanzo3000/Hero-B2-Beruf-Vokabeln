//
//  AppLog.swift
//  B2 Berufssprachkurs
//

import OSLog

enum AppLog {
    static let subscription = Logger(subsystem: Bundle.main.bundleIdentifier ?? "B2Berufssprachkurs", category: "subscription")
}
