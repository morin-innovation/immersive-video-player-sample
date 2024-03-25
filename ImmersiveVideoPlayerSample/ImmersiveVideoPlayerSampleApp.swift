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

@main
struct ImmersiveVideoPlayerSampleApp: App {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some Scene {
        WindowGroup(id: AppSceneId.mainWindow.rawValue) {
            ContentView()
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: AppSceneId.immersiveSpace.rawValue) {
            ImmersiveView()
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
