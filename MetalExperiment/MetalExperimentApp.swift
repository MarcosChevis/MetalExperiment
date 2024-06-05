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
                CanvasView { drawer in
                    drawer
                        .setBackgroundColor(color: .green)
                } update: { drawer, frame in
                    drawer
                        .drawCircle(center: .zero, radius: 1)
                }
                    .ignoresSafeArea()
            }
        }
    }
}
