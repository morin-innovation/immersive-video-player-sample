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

/// Immersive video
///
/// Inspired by Apple Destination Video sample code
/// https://developer.apple.com/documentation/visionos/destination-video/
struct ImmersiveView: View {
    @Environment(\.playerState) private var playerState

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        RealityView { content in
            let videoEntity = ModelEntity()
            let material = VideoMaterial(avPlayer: playerState.avPlayer)
            videoEntity.components.set(ModelComponent(
                mesh: .generateSphere(radius: 1E3),
                materials: [material]
            ))

            videoEntity.scale *= .init(x: -1, y: 1, z: 1)
            videoEntity.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)

            let angle = Angle.degrees(90)
            let rotation = simd_quatf(angle: Float(angle.radians), axis: SIMD3<Float>(0, 1, 0))
            videoEntity.transform.rotation = rotation

            content.add(videoEntity)
        }
        .transition(.opacity)
        .upperLimbVisibility(.hidden)
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
}
