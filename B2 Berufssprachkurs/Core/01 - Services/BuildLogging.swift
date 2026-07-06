//
//  BuildLogging.swift
//  B2 Berufssprachkurs
//
//  Shared compile-time gate for verbose diagnostics in Debug and Release-Logging builds.
//

import Foundation

enum BuildLogging {
    /// `true` for Debug and Release-Logging (`LOGGING`); `false` for App Store Release.
    static var isEnabled: Bool {
        #if DEBUG || LOGGING
        true
        #else
        false
        #endif
    }
}
