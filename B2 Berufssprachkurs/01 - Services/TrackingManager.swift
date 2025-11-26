//
//  TrackingManager.swift
//  B2 Berufssprachkurs
//
//  Created for version 1.0.1
//

import AppTrackingTransparency
import AdSupport

class TrackingManager {
    static func requestTrackingPermission() {
        // Delay request to ensure app is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Tracking authorized")
                case .denied:
                    print("Tracking denied")
                case .notDetermined:
                    print("Tracking not determined")
                case .restricted:
                    print("Tracking restricted")
                @unknown default:
                    print("Unknown tracking status")
                }
            }
        }
    }
    
    static var trackingStatus: ATTrackingManager.AuthorizationStatus {
        return ATTrackingManager.trackingAuthorizationStatus
    }
}

