//
//  MetalExperimentApp.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 16/02/24.
//

import SwiftUI

@main
struct MetalExperimentApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                ProcessingView { drawer in
                    
                } update: { drawer, frame in
                    drawer.drawSquare(center: .init(x: cos(frame / 1000) / 2, y: sin(frame / 1000) / 2), sideSize: 0.5, color: .green, rotation: Float(frame / 100))
                }
                    .ignoresSafeArea()
            }
        }
    }
}
