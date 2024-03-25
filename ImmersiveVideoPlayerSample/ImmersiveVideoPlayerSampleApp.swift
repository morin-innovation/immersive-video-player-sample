//
//  ImmersiveVideoPlayerSampleApp.swift
//  ImmersiveVideoPlayerSample
//
//  Created by Florent Morin on 25/03/2024.
//

import SwiftUI

@main
struct ImmersiveVideoPlayerSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
