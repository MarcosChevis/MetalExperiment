//
//  Renderer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 16/02/24.
//

import MetalKit
import SwiftUI

final class MetalViewCoordinator {
    private(set) var renderer: Renderer
    private(set) var metalView: MTKView
    
    init(renderer: Renderer) {
        self.renderer = renderer
        self.metalView = MTKView()
        
        setupView()
    }
    
    private func setupView() {
        metalView.delegate = renderer
        metalView.preferredFramesPerSecond = 60
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            metalView.device = metalDevice
        }
        
        metalView.framebufferOnly = false
        metalView.drawableSize = metalView.frame.size
    }
}
