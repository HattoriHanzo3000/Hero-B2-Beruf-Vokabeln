//
//  AppearanceManager.swift
//  B2 Berufssprachkurs
//
//  Manages and publishes app-wide light, dark, or system appearance preference.
//  Created: 24.11.25.
//

import SwiftUI
import Combine

// MARK: - Manager

@MainActor
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @Published var colorScheme: ColorScheme? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: Lifecycle

    private init() {
        updateColorScheme()
        
        // Observe UserDefaults changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateColorScheme()
            }
            .store(in: &cancellables)
    }
    
    // MARK: Helpers

    private func updateColorScheme() {
        let preference = userDefaults.string(forKey: "appearancePreference") ?? "System"
        
        switch preference {
        case "Light":
            colorScheme = .light
        case "Dark":
            colorScheme = .dark
        case "System":
            colorScheme = nil // nil means use system default
        default:
            colorScheme = nil
        }
    }
}

