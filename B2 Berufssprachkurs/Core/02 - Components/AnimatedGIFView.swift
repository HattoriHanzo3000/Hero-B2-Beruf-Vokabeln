//
//  AnimatedGIFView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit
import ImageIO

// MARK: - Animated GIF View
struct AnimatedGIFView: UIViewRepresentable {
    let gifName: String
    let contentMode: UIView.ContentMode
    let shouldAnimate: Bool
    let loops: Bool

    init(
        gifName: String,
        contentMode: UIView.ContentMode = .scaleAspectFit,
        shouldAnimate: Bool = true,
        loops: Bool = false
    ) {
        self.gifName = gifName
        self.contentMode = contentMode
        self.shouldAnimate = shouldAnimate
        self.loops = loops
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)

        context.coordinator.imageView = imageView

        applyDecodedGif(to: imageView, context: context)

        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let imageView = context.coordinator.imageView else { return }

        imageView.contentMode = contentMode

        if context.coordinator.cachedAssetName != gifName {
            invalidateGifCache(context.coordinator)
            context.coordinator.lastShouldAnimate = nil
            applyDecodedGif(to: imageView, context: context)
        }

        if shouldAnimate {
            if context.coordinator.lastShouldAnimate != true {
                context.coordinator.lastShouldAnimate = true
                restartPlayback(imageView, context: context)
            }
        } else {
            if context.coordinator.lastShouldAnimate != false {
                context.coordinator.lastShouldAnimate = false
                imageView.stopAnimating()
                imageView.layer.removeAnimation(forKey: "gif_keyframe_animation")
            }
        }
    }

    // MARK: - Decode & apply (once per asset per coordinator)

    private func applyDecodedGif(to imageView: UIImageView, context: Context) {
        guard let d = decodedFrames(for: context) else {
            imageView.animationImages = nil
            imageView.image = nil
            context.coordinator.playbackMode = .caKeyframe
            return
        }

        let uniform = Self.delaysAreUniform(d.frameDelays)

        if uniform, let animated = UIImage.animatedImage(with: d.images, duration: d.duration) {
            imageView.animationImages = nil
            imageView.image = animated
            imageView.animationRepeatCount = loops ? 0 : 1
            context.coordinator.animationConfig = (d.images, d.duration, d.frameDelays)
            context.coordinator.playbackMode = .uiImageViewAnimated
        } else if uniform {
            imageView.animationImages = d.images
            imageView.animationDuration = d.duration
            imageView.animationRepeatCount = loops ? 0 : 1
            imageView.image = d.images.first
            context.coordinator.animationConfig = (d.images, d.duration, d.frameDelays)
            context.coordinator.playbackMode = .animationImages
        } else {
            imageView.animationImages = nil
            imageView.image = d.images.first
            context.coordinator.animationConfig = (d.images, d.duration, d.frameDelays)
            context.coordinator.playbackMode = .caKeyframe
        }
    }

    /// Restarts playback using existing `UIImageView` state only (no disk / ImageIO).
    private func restartPlayback(_ imageView: UIImageView, context: Context) {
        switch context.coordinator.playbackMode {
        case .uiImageViewAnimated:
            guard let img = imageView.image, img.images != nil else { return }
            imageView.stopAnimating()
            imageView.startAnimating()
        case .animationImages:
            guard let imgs = imageView.animationImages, !imgs.isEmpty else { return }
            imageView.stopAnimating()
            imageView.startAnimating()
        case .caKeyframe:
            guard let config = context.coordinator.animationConfig else { return }
            let duration = max(config.duration, 0.1)
            let contents = config.images.compactMap { $0.cgImage }
            guard !contents.isEmpty else { return }

            imageView.layer.removeAnimation(forKey: "gif_keyframe_animation")
            let animation = CAKeyframeAnimation(keyPath: "contents")
            animation.values = contents
            animation.keyTimes = Self.normalizedKeyTimes(for: config.frameDelays, totalDuration: duration)
            animation.duration = duration
            animation.calculationMode = .discrete
            animation.repeatCount = loops ? .infinity : 0
            animation.isRemovedOnCompletion = true
            imageView.layer.add(animation, forKey: "gif_keyframe_animation")
        }
    }

    /// Cumulative start times for each frame (0…1), matching GIF per-frame delays.
    private static func normalizedKeyTimes(for delays: [Double], totalDuration: Double) -> [NSNumber] {
        let t = max(totalDuration, 0.0001)
        var cumulative = 0.0
        return delays.map { delay in
            let key = cumulative / t
            cumulative += delay
            return NSNumber(value: key)
        }
    }

    private static func delaysAreUniform(_ delays: [Double]) -> Bool {
        guard delays.count > 1 else { return true }
        let first = delays[0]
        return delays.dropFirst().allSatisfy { abs($0 - first) < 0.001 }
    }

    // MARK: - Coordinator

    enum GifPlaybackMode {
        case uiImageViewAnimated
        case animationImages
        case caKeyframe
    }

    final class Coordinator {
        var imageView: UIImageView?
        var animationConfig: (images: [UIImage], duration: Double, frameDelays: [Double])?
        /// Avoid decoding the same bundle GIF on every SwiftUI update.
        var cachedAssetName: String?
        var decodedFrames: (images: [UIImage], duration: Double, frameDelays: [Double])?
        /// Only restart playback when `shouldAnimate` becomes true (or asset changes), not on every parent re-render.
        var lastShouldAnimate: Bool?
        var playbackMode: GifPlaybackMode = .caKeyframe
    }

    private func invalidateGifCache(_ coordinator: Coordinator) {
        coordinator.cachedAssetName = nil
        coordinator.decodedFrames = nil
        coordinator.animationConfig = nil
        coordinator.playbackMode = .caKeyframe
    }

    /// Single ImageIO decode per asset name while the coordinator lives.
    private func decodedFrames(for context: Context) -> (images: [UIImage], duration: Double, frameDelays: [Double])? {
        if context.coordinator.cachedAssetName == gifName, let cached = context.coordinator.decodedFrames {
            return cached
        }
        guard let decoded = decodeGifFramesFromBundle() else {
            context.coordinator.cachedAssetName = gifName
            context.coordinator.decodedFrames = nil
            return nil
        }
        context.coordinator.cachedAssetName = gifName
        context.coordinator.decodedFrames = decoded
        return decoded
    }

    private func decodeGifFramesFromBundle() -> (images: [UIImage], duration: Double, frameDelays: [Double])? {
        guard let url = resolveGifURL() else { return nil }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var frameDelays: [Double] = []
        var totalDuration: Double = 0

        for index in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) {
                let delay = GIFBundleLookup.frameDelay(at: index, source: source)
                frameDelays.append(delay)
                totalDuration += delay
                images.append(UIImage(cgImage: cgImage))
            }
        }

        if images.isEmpty { return nil }
        if totalDuration <= 0 {
            let per = 1.0 / 24.0
            frameDelays = Array(repeating: per, count: images.count)
            totalDuration = Double(images.count) * per
        }
        return (images, totalDuration, frameDelays)
    }

    private func resolveGifURL() -> URL? {
        let candidates: [String]
        if gifName.hasSuffix("Dark") {
            let baseName = String(gifName.dropLast(4))
            candidates = [gifName, baseName]
        } else {
            candidates = [gifName]
        }
        for name in candidates {
            if let url = GIFBundleLookup.url(forResourceName: name) {
                return url
            }
        }
        return nil
    }
}
