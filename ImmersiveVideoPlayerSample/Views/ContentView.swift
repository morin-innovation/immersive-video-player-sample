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

import SwiftUI
import RealityKit
import PhotosUI
import UniformTypeIdentifiers

/// Player controls (stop, play/pause, seek)
private struct PlayerControlsView: View {
    @Environment(\.playerState) private var playerState

    @State private var sliderProgress: Double = 0

    var body: some View {
        HStack(spacing: 20) {
            HStack {
                Button {
                    if playerState.isPlaying {
                        playerState.pause()
                    } else {
                        playerState.play()
                    }
                } label: {
                    Label(playerState.isPlaying ? "Pause" : "Play", systemImage: playerState.isPlaying ? "pause.fill" : "play.fill")
                        .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                        .labelStyle(IconOnlyLabelStyle())
                }
                Button {
                    playerState.stop()
                } label: {
                    Label("Stop", systemImage: "square.fill")
                        .labelStyle(IconOnlyLabelStyle())
                }
            }
            Slider(value: $sliderProgress, in: 0...playerState.videoDuration) { editing in
                playerState.pause()
                playerState.seek(to: sliderProgress)
            }
        }
        .disabled(playerState.currentItemURL == nil)

        .onChange(of: playerState.progress) { _, newValue in
            withAnimation {
                sliderProgress = newValue
            }
        }
    }
}

/// Video picker which use Photos library
private struct VideoPickerView: View {
    @Binding var showImmersiveSpace: Bool
    @Environment(\.playerState) private var playerState
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .videos) {
                Label("Select Video from Library", systemImage: "photo.badge.plus")
                    .labelStyle(IconOnlyLabelStyle())
            }
            .task(id: selectedItem) {
                await useSelectedItem()
            }
    }

    private func useSelectedItem() async {
        defer {
            selectedItem = nil
        }

        guard let selectedItem else { return}

        var videoURL: URL? = nil

        do {
            // Retrieve video as URL or Data
            if let result = try await selectedItem.loadTransferable(type: URL.self) {
                videoURL = result
            } else if let result = try await selectedItem.loadTransferable(type: Data.self) {
                let fileExt: String

                if selectedItem.supportedContentTypes.contains([UTType.mpeg4Movie]) {
                    fileExt = "mp4"
                } else {
                    fileExt = "mov"
                }

                let tmpFileURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(fileExt)")

                try result.write(to: tmpFileURL)
                videoURL = tmpFileURL
            }
        } catch {
            print(error)
        }

        // Open video URL into immersive space
        if let videoURL {
            playerState.open(url: videoURL)
            showImmersiveSpace = true
        }
    }
}

/// Main UI view
struct ContentView: View {
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.playerState) private var playerState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace


    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("360° Video player demo")
                    .font(.title)

                Spacer(minLength: 10)

                VideoPickerView(showImmersiveSpace: $showImmersiveSpace)
            }

            Divider()

            PlayerControlsView()
        }
        .padding(40)
        .frame(minWidth: 500, maxWidth: 800, minHeight: 100, maxHeight: 140)
        .onChange(of: playerState.currentItemURL) { _, newItem in
            if newItem == nil {
                showImmersiveSpace = false
            }
        }
        .task(id: scenePhase) {
            guard immersiveSpaceIsShown else { return }

            if scenePhase == .background || scenePhase == .inactive {
                showImmersiveSpace = false
            }
        }
        .task(id: showImmersiveSpace) {
            if showImmersiveSpace {
                switch await openImmersiveSpace(id: AppSceneId.immersiveSpace.rawValue) {
                case .opened:
                    immersiveSpaceIsShown = true
                case .error, .userCancelled:
                    fallthrough
                @unknown default:
                    immersiveSpaceIsShown = false
                    showImmersiveSpace = false
                }
            } else if immersiveSpaceIsShown {
                await dismissImmersiveSpace()
                immersiveSpaceIsShown = false
                playerState.stop()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
