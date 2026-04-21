//
//  VideoBundleLookup.swift
//  B2 Berufssprachkurs
//
//  Shared bundle search and duration lookup for mascot video assets.
//  Created: 20.04.26.
//

import AVFoundation
import Foundation

enum VideoBundleLookup {
    static let searchSubdirectories: [String?] = [
        nil,
        "04 - Videos",
        "Videos",
        "Resources/04 - Videos",
        "09 - Resources/04 - Videos",
        "Core/09 - Resources/04 - Videos"
    ]

    static func url(forResourceName name: String, extension ext: String = "mov") -> URL? {
        for subdirectory in searchSubdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }

    static func resourceExists(resourceName name: String, extension ext: String = "mov") -> Bool {
        url(forResourceName: name, extension: ext) != nil
    }

    static func duration(forResourceName name: String, extension ext: String = "mov") -> TimeInterval? {
        guard let url = url(forResourceName: name, extension: ext) else { return nil }
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        return seconds
    }
}
