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
                ProcessingView()
                    .ignoresSafeArea()
                    .frame(width: 1000, height: 1000)
            }
        }
    }
}
