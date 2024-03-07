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
    @Binding
    private(set) var drawer: Drawer
    
    init(drawer: Binding<Drawer>) {
        self.renderer = Renderer()
        self.metalView = MTKView()
        self._drawer = drawer
        self.drawer.renderer = renderer
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

final class Drawer {
    var renderer: Renderer?
    
    
    func addPolygon(poly: RegularPolygon) {
        renderer?.polygons.append(poly)
    }
}
