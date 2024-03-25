//===----------------------------------------------------------------------===//
//
// This source file is part of the Immersive Video Player Sample open source project
//
// Copyright (c) 2024 Morin Innovation & Florent Morin
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// https://github.com/morin-innovation/immersive-video-player-sample/blob/main/LICENSE.txt
//
//===----------------------------------------------------------------------===//

import Foundation
import Observation
import SwiftUI
import AVFoundation
import AsyncAlgorithms

/// Global video player state
@Observable final class PlayerState {
    static let shared = PlayerState()

    /// AVPlayer used to map with VideoMaterial
    let avPlayer = AVPlayer()

    /// Progress of the video
    private(set) var progress: Double = 0

    /// Video duration
    private(set) var videoDuration: Double = 1

    /// Is current video playing?
    private(set) var isPlaying = false
    
    /// Is there a video playing?
    private(set) var currentItemURL: URL? = nil

    /// Used with video coming out of sandbox
    @ObservationIgnored
    private var isSecurelyAccessToCurrentItem = false

    private init() {
        avPlayer.actionAtItemEnd = .none

        // Loop reading
        Task {
            for await _ in NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification) {
                await avPlayer.currentItem?.seek(to: .zero)
            }
        }

        // Update progress
        Task {
            let clock = ContinuousClock()
            let timerSequence = AsyncTimerSequence.repeating(every: .seconds(0.1), clock: clock)
            let sequence = chain([clock.now].async, timerSequence)

            for await _ in sequence where currentItemURL != nil {
                progress = avPlayer.currentTime().seconds
            }
        }
    }

    /// Open file at specified URL
    func open(url: URL) {
        let previousItemURL = currentItemURL
        let isSecurelyAccessToPreviousItem = isSecurelyAccessToCurrentItem

        isSecurelyAccessToCurrentItem = url.startAccessingSecurityScopedResource()
        currentItemURL = url

        let item = AVPlayerItem(url: url)
        avPlayer.replaceCurrentItem(with: item)

        if let previousItemURL, isSecurelyAccessToPreviousItem {
            previousItemURL.stopAccessingSecurityScopedResource()
        }

        updateVideoDuration()
        play()
    }

    /// Stop current video and set current item to `nil`
    func stop() {
        defer {
            avPlayer.replaceCurrentItem(with: nil)
            currentItemURL = nil
            progress = 0
        }

        guard let currentItemURL else { return }

        if isSecurelyAccessToCurrentItem {
            currentItemURL.stopAccessingSecurityScopedResource()
        }
    }

    /// Go to specified video progress
    func seek(to newProgress: Double) {
        let time = CMTime(seconds: newProgress, preferredTimescale: 600)
        avPlayer.seek(to: time)
        progress = newProgress
    }

    /// Update video duration based on asset
    private func updateVideoDuration() {
        guard let asset = avPlayer.currentItem?.asset else { return }

        Task {
            let duration = try await asset.load(.duration)
            guard asset.status(of: .duration) == .loaded(duration) else { return }
            await MainActor.run {
                self.videoDuration = CMTimeGetSeconds(duration)
            }
        }
    }

    /// Start video player
    func play() {
        avPlayer.play()
        isPlaying = true
    }

    /// Pause video player
    func pause() {
        avPlayer.pause()
        isPlaying = false
    }
}

// MARK: - Environment

private struct PlayerStateEnvironmentKey: EnvironmentKey {
    static let defaultValue = PlayerState.shared
}

extension EnvironmentValues {
    var playerState: PlayerState {
        get {
            self[PlayerStateEnvironmentKey.self]
        }
        set {
            self[PlayerStateEnvironmentKey.self] = newValue
        }
    }
}
