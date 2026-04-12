//
//  GIFBundleLookup.swift
//  B2 Berufssprachkurs
//
//  Shared bundle search for GIF assets (folder references vs flat resources).
//

import Foundation
import ImageIO

enum GIFBundleLookup {
    static let searchSubdirectories: [String?] = [
        nil,
        "02 - Gifs",
        "GIFs",
        "Resources/02 - Gifs",
        "09 - Resources/02 - Gifs",
        "Core/09 - Resources/02 - Gifs"
    ]

    /// First matching `name.gif` in the bundle search order used across the app.
    static func url(forResourceName name: String, extension ext: String = "gif") -> URL? {
        for sub in searchSubdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub) {
                return url
            }
        }
        return nil
    }

    static func resourceExists(resourceName name: String, extension ext: String = "gif") -> Bool {
        url(forResourceName: name, extension: ext) != nil
    }

    /// Sum of per-frame delays (matches `AnimatedGIFView` decoding). Used to align hide timers with actual GIF length.
    static func totalAnimationDuration(forResourceName name: String) -> Double? {
        guard let url = url(forResourceName: name) else { return nil }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(source)
        var frameImages = 0
        var totalDuration: Double = 0
        for index in 0..<frameCount {
            if CGImageSourceCreateImageAtIndex(source, index, nil) != nil {
                frameImages += 1
                totalDuration += frameDelay(at: index, source: source)
            }
        }
        guard frameImages > 0 else { return nil }
        if totalDuration <= 0 { totalDuration = Double(frameImages) * (1.0 / 24.0) }
        return totalDuration
    }

    /// Per-frame display delay (ImageIO GIF dictionary). Shared with `AnimatedGIFView` so timing matches.
    static func frameDelay(at index: Int, source: CGImageSource) -> Double {
        var duration = 0.1
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return duration
        }
        if let unclampedDelayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclampedDelayTime > 0 {
            duration = unclampedDelayTime
        } else if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime] as? Double, delayTime > 0 {
            duration = delayTime
        }
        if duration < 0.02 { duration = 0.1 }
        return duration
    }
}
