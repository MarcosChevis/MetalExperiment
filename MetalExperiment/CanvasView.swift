//
//  ProcessingView.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 06/03/24.
//

import SwiftUI
import MetalKit

struct CanvasView: View {
    
    @State private var drawer: Drawer = Drawer()
    @State private var renderer: Renderer = Renderer()
    var setup: (Drawer) -> Void
    var update: (Drawer, Double) -> Void
    

    
    var body: some View {
        MetalViewRepresentable(renderer: renderer)
            .onAppear {
                renderer.update = { frame in
                    update(drawer, frame)
                    return drawer.popPolygons()
                }
                setup(drawer)
            }
    }
}

#Preview {
    CanvasView { drawer in
        
    } update: { drawer, frame in
        drawer.drawSquare(center: .init(x: cos(frame / 1000) / 2, y: sin(frame / 1000) / 2), sideSize: 0.5, color: .green, rotation: Float(frame / 100))
    }
        .ignoresSafeArea()
}
