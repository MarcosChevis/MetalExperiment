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
    var update: (() -> Void)? {
        didSet {
            renderer?.update = update
            update?()
        }
    }
    var time = TimeInterval.zero
    private var timer: Timer? = nil
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self] _ in
            self?.time += 0.01
        })
    }
    
    func addPolygon(poly: RegularPolygon) {
        renderer?.polygons.append(poly)
    }
    
    func setClearColor(color: (red: Double, green: Double, blue: Double, opacity: Double)) {
        renderer?.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.opacity)
    }
}
