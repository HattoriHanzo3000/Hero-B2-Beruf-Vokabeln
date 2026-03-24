//
//  AppearanceManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import Combine

@MainActor
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @Published var colorScheme: ColorScheme? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    private init() {
        updateColorScheme()
        
        // Observe UserDefaults changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateColorScheme()
            }
            .store(in: &cancellables)
    }
    
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

