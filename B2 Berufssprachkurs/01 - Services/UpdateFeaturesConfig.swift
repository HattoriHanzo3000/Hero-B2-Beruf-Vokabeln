//
//  UpdateFeaturesConfig.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation

/// Configuration for update features per version
/// Add your update features here for each version
struct UpdateFeaturesConfig {
    /// Dictionary mapping version numbers to their feature lists
    /// Add new versions here with their features
    private static let versionFeatures: [String: [String]] = [
        "1.0.5": [
            // Add your features here, one per line
            // Example: "Improved performance and stability"
            // Example: "New vocabulary categories"
            // Example: "Enhanced user interface"
        ],
        "1.0.4": [
            // Previous version features
        ],
        "1.0.3": [
            // Previous version features
        ]
    ]
    
    /// Returns the features for a given version
    static func getFeatures(for version: String) -> [String]? {
        return versionFeatures[version]
    }
}
